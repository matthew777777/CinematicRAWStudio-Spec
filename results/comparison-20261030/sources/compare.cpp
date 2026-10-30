// SPDX-License-Identifier: Apache-2.0
// In-memory, lossless RAW payload comparison. No camera or storage throughput claim.
#include <craw/Encoder.h>
#include <craw/Reader.h>
#include <jxl/encode_cxx.h>
#include <jxl/decode_cxx.h>
#include <jxl/thread_parallel_runner_cxx.h>
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <sys/resource.h>
#include <vector>

using Clock = std::chrono::steady_clock;
static void require(bool b, const char* message) { if (!b) throw std::runtime_error(message); }
static std::vector<uint8_t> read(const std::string& p) {
  std::ifstream f(p, std::ios::binary); require(bool(f), "cannot open input");
  return {std::istreambuf_iterator<char>(f), {}};
}
static void write(const std::string& p, const void* data, size_t size) {
  std::ofstream f(p, std::ios::binary); f.write(static_cast<const char*>(data), size);
  require(bool(f), "cannot write output");
}
static long rss() {
  rusage r{}; require(getrusage(RUSAGE_SELF, &r) == 0, "getrusage failed");
#ifdef __APPLE__
  return r.ru_maxrss;
#else
  return r.ru_maxrss * 1024;
#endif
}
static double cpuMs() {
  rusage r{}; getrusage(RUSAGE_SELF, &r);
  return (r.ru_utime.tv_sec + r.ru_stime.tv_sec) * 1000.0 +
         (r.ru_utime.tv_usec + r.ru_stime.tv_usec) / 1000.0;
}
// Four CFA positions stacked vertically as grayscale, no rescaling or demosaic.
static std::vector<uint16_t> reorder(const std::vector<uint16_t>& in, unsigned w, unsigned h, bool inverse) {
  std::vector<uint16_t> out(in.size());
  for (unsigned y = 0; y < h; ++y) for (unsigned x = 0; x < w; ++x) {
    size_t a = size_t(y) * w + x;
    size_t b = size_t((y % 2) * 2 + x % 2) * (w/2) * (h/2) + size_t(y/2) * (w/2) + x/2;
    if (inverse) out[a] = in[b]; else out[b] = in[a];
  }
  return out;
}
struct Codec {
  unsigned w, h, bits, cfa, threads;
  std::string mode;
  bool jxl() const { return mode.rfind("jxl", 0) == 0; }
  bool planes() const { return mode.find("planes") != std::string::npos; }
  std::vector<uint8_t> encode(const std::vector<uint16_t>& raw) const {
    std::vector<uint8_t> out;
    if (!jxl()) {
      craw::FrameDesc d; d.width=w; d.height=h; d.bitDepth=bits; d.cfa=static_cast<craw::Cfa>(cfa);
      d.codec=std::stoi(mode.substr(4)); d.frameCrc=false; d.pfor=false;
      craw::encodeFrame(raw.data(), w, d, out, threads); return out;
    }
    auto enc=JxlEncoderMake(nullptr);
    // One requested thread uses libjxl's synchronous path, with no worker pool.
    auto runner=JxlThreadParallelRunnerMake(nullptr, threads > 1 ? threads : 0);
    require(bool(enc) && bool(runner), "JXL allocation failed");
    if (threads > 1) require(JxlEncoderSetParallelRunner(enc.get(), JxlThreadParallelRunner, runner.get()) == JXL_ENC_SUCCESS, "JXL runner");
    JxlBasicInfo info; JxlEncoderInitBasicInfo(&info);
    info.xsize=planes()?w/2:w; info.ysize=planes()?h*2:h;
    info.bits_per_sample=bits; info.num_color_channels=1; info.uses_original_profile=JXL_TRUE;
    require(JxlEncoderSetBasicInfo(enc.get(), &info)==JXL_ENC_SUCCESS, "JXL basic info");
    JxlColorEncoding color; JxlColorEncodingSetToLinearSRGB(&color, JXL_TRUE);
    require(JxlEncoderSetColorEncoding(enc.get(), &color)==JXL_ENC_SUCCESS, "JXL color");
    auto* settings=JxlEncoderFrameSettingsCreate(enc.get(), nullptr);
    require(settings, "JXL frame settings");
    require(JxlEncoderSetFrameLossless(settings,JXL_TRUE)==JXL_ENC_SUCCESS, "JXL lossless");
    require(JxlEncoderFrameSettingsSetOption(settings,JXL_ENC_FRAME_SETTING_EFFORT,mode[5]-'0')==JXL_ENC_SUCCESS,"JXL effort");
    JxlBitDepth depth{JXL_BIT_DEPTH_FROM_CODESTREAM,0,0};
    require(JxlEncoderSetFrameBitDepth(settings,&depth)==JXL_ENC_SUCCESS,"JXL input bit depth");
    JxlPixelFormat format{1,JXL_TYPE_UINT16,JXL_NATIVE_ENDIAN,0};
    auto cells=planes()?reorder(raw,w,h,false):std::vector<uint16_t>{};
    require(JxlEncoderAddImageFrame(settings,&format,planes()?cells.data():raw.data(),raw.size()*2)==JXL_ENC_SUCCESS,"JXL input");
    JxlEncoderCloseInput(enc.get()); out.resize(raw.size()*2+65536);
    uint8_t* next=out.data(); size_t available=out.size();
    for (;;) {
      auto status=JxlEncoderProcessOutput(enc.get(),&next,&available);
      if(status==JXL_ENC_SUCCESS) {out.resize(next-out.data());return out;}
      require(status==JXL_ENC_NEED_MORE_OUTPUT,"JXL encode failed");
      size_t used=next-out.data();out.resize(out.size()*2);next=out.data()+used;available=out.size()-used;
    }
  }
  std::vector<uint16_t> decode(const std::vector<uint8_t>& payload) const {
    std::vector<uint16_t> out;
    if(!jxl()) {
      const auto info=craw::decodeFrame(payload.data(),payload.size(),out,threads);
      require(info.width==w && info.height==h && info.bitDepth==bits,"CRAW geometry mismatch");return out;
    }
    auto dec=JxlDecoderMake(nullptr);
    auto runner=JxlThreadParallelRunnerMake(nullptr,threads>1?threads:0);
    require(bool(dec) && bool(runner),"JXL allocation failed");
    if(threads>1) require(JxlDecoderSetParallelRunner(dec.get(),JxlThreadParallelRunner,runner.get())==JXL_DEC_SUCCESS,"JXL decoder runner");
    require(JxlDecoderSubscribeEvents(dec.get(),JXL_DEC_BASIC_INFO|JXL_DEC_FULL_IMAGE)==JXL_DEC_SUCCESS,"JXL events");
    require(JxlDecoderSetInput(dec.get(),payload.data(),payload.size())==JXL_DEC_SUCCESS,"JXL compressed input");
    JxlDecoderCloseInput(dec.get());
    JxlPixelFormat format{1,JXL_TYPE_UINT16,JXL_NATIVE_ENDIAN,0}; bool full=false;
    for(;;) {
      auto status=JxlDecoderProcessInput(dec.get());
      if(status==JXL_DEC_BASIC_INFO) {
        JxlBasicInfo info;require(JxlDecoderGetBasicInfo(dec.get(),&info)==JXL_DEC_SUCCESS,"JXL read info");
        require(info.xsize==(planes()?w/2:w) && info.ysize==(planes()?h*2:h) && info.bits_per_sample==bits,"JXL geometry mismatch");
      } else if(status==JXL_DEC_NEED_IMAGE_OUT_BUFFER) {
        size_t size=0;require(JxlDecoderImageOutBufferSize(dec.get(),&format,&size)==JXL_DEC_SUCCESS && size==size_t(w)*h*2,"JXL output size");
        out.resize(size/2);require(JxlDecoderSetImageOutBuffer(dec.get(),&format,out.data(),size)==JXL_DEC_SUCCESS,"JXL output");
        JxlBitDepth depth{JXL_BIT_DEPTH_FROM_CODESTREAM,0,0};
        require(JxlDecoderSetImageOutBitDepth(dec.get(),&depth)==JXL_DEC_SUCCESS,"JXL output depth");
      } else if(status==JXL_DEC_FULL_IMAGE) full=true;
      else if(status==JXL_DEC_SUCCESS) {require(full,"JXL incomplete image");return planes()?reorder(out,w,h,true):out;}
      else throw std::runtime_error("JXL decode failed");
    }
  }
};
int main(int argc,char** argv) {
  try {
    if(argc==5 && std::string(argv[1])=="extract") {
      craw::Reader reader(argv[2]);size_t index=std::stoull(argv[3]);
      require(index<reader.frameCount(),"frame index outside take");
      auto frame=reader.frame(index);std::vector<uint16_t> raw;
      auto info=craw::decodeFrame(frame.payload,frame.payloadSize,raw,1);
      require(info.cfa!=craw::Cfa::RGB,"benchmark expects Bayer input");
      write(argv[4],raw.data(),raw.size()*2);
      std::cout<<"{\"width\":"<<info.width<<",\"height\":"<<info.height<<",\"bits\":"<<int(info.bitDepth)
        <<",\"cfa\":"<<int(info.cfa)<<",\"frame_count\":"<<reader.frameCount()<<",\"timestamp_ns\":"<<frame.timestampNs<<"}\n";return 0;
    }
    require(argc==14,"usage: craw_compare measure RAW W H BITS CFA MODE THREADS encode|decode PAYLOAD REPS SECONDS WARMUPS; or extract TAKE INDEX RAW");
    require(std::string(argv[1])=="measure","unknown command");
    Codec c{unsigned(std::stoul(argv[3])),unsigned(std::stoul(argv[4])),unsigned(std::stoul(argv[5])),unsigned(std::stoul(argv[6])),unsigned(std::stoul(argv[8])),argv[7]};
    require(c.w && c.h && !(c.w%2) && !(c.h%2) && c.bits>=1 && c.bits<=16 && c.cfa<4 && c.threads>=1,"invalid geometry or thread count");
    require(c.mode=="craw1"||c.mode=="craw2"||c.mode=="craw3"||c.mode=="craw4"||c.mode=="jxl-e1-mosaic"||c.mode=="jxl-e2-mosaic"||c.mode=="jxl-e3-mosaic"||c.mode=="jxl-e1-planes"||c.mode=="jxl-e2-planes"||c.mode=="jxl-e3-planes","unknown mode");
    auto bytes=read(argv[2]);require(bytes.size()==size_t(c.w)*c.h*2,"RAW size mismatch");
    std::vector<uint16_t> raw(bytes.size()/2);
    for(size_t i=0;i<raw.size();++i) raw[i]=bytes[2*i]|uint16_t(bytes[2*i+1])<<8;
    bytes.clear();bytes.shrink_to_fit();
    require(*std::max_element(raw.begin(),raw.end())<(1u<<c.bits),"sample exceeds declared bit depth");
    std::string op=argv[9];require(op=="encode"||op=="decode","unknown operation");
    bool encode=op=="encode";std::vector<uint8_t> payload=encode?std::vector<uint8_t>{}:read(argv[10]);
    int reps=std::stoi(argv[11]),warmups=std::stoi(argv[13]);double seconds=std::stod(argv[12]);
    require(reps>=1 && warmups>=0 && seconds>=0,"invalid repetitions");
    std::vector<uint8_t> firstPayload;
    auto once=[&]() {
      auto t=Clock::now();double cpu=cpuMs();std::vector<uint16_t> restored;
      if(encode)payload=c.encode(raw);else restored=c.decode(payload);
      double cpuElapsed=cpuMs()-cpu;
      double elapsed=std::chrono::duration<double,std::milli>(Clock::now()-t).count();
      // Check every decode and deterministic encode outside codec timing.
      // A separate decode process verifies the final payload against RAW, so
      // encode RSS is not contaminated by decoder allocations.
      if(encode) {
        if(firstPayload.empty()) firstPayload=payload;
        else require(firstPayload==payload,"non-deterministic encoded payload");
      } else require(raw==restored,"RAW round trip differs");
      return std::pair<double,double>{elapsed,cpuElapsed};
    };
    for(int i=0;i<warmups;++i)once();
    std::vector<double> times,cpus,starts;auto start=Clock::now();
    do {
      starts.push_back(std::chrono::duration<double>(Clock::now()-start).count());
      auto [ms,cpu]=once();times.push_back(ms);cpus.push_back(cpu);
    }while(times.size()<size_t(reps)||std::chrono::duration<double>(Clock::now()-start).count()<seconds);
    double wall=std::chrono::duration<double>(Clock::now()-start).count();
    if(encode)write(argv[10],payload.data(),payload.size());
    std::cout<<std::setprecision(10)<<"{\"payload_bytes\":"<<payload.size()<<",\"peak_rss_bytes\":"<<rss()<<",\"wall_seconds\":"<<wall<<",\"jxl_version\":"<<JxlEncoderVersion()<<",\"verified\":"<<(encode?"false":"true");
    auto array=[&](const char* name,const std::vector<double>& v){std::cout<<",\""<<name<<"\":[";for(size_t i=0;i<v.size();++i){if(i)std::cout<<',';std::cout<<v[i];}std::cout<<']';};
    array("ms",times);array("cpu_ms",cpus);array("start_seconds",starts);std::cout<<"}\n";
  }catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}
}
