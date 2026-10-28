#pragma once
#include <cstdint>
#include <vector>
void enc(const std::vector<uint16_t>&,int,int,int,std::vector<uint8_t>&);
void dec(const std::vector<uint8_t>&,std::vector<uint16_t>&);
