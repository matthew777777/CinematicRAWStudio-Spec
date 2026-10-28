#include "api.h"
#include <craw/Encoder.h>
void enc(const std::vector<uint16_t>&r,int w,int h,int codec,std::vector<uint8_t>&o){craw::FrameDesc d;d.width=w;d.height=h;d.bitDepth=10;d.cfa=craw::Cfa::GBRG;d.codec=codec;d.frameCrc=false;craw::encodeFrame(r.data(),w,d,o,1);}
