#include "api.h"
#include <craw/Decoder.h>
void dec(const std::vector<uint8_t>&p,std::vector<uint16_t>&o){craw::decodeFrame(p.data(),p.size(),o,1);}
