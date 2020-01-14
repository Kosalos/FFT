#pragma once
#include <simd/simd.h>

struct TVertex {
    simd_float3 pos;
    simd_float3 nrm;
    simd_float2 txt;
    simd_float4 color;
    unsigned char drawStyle;
};

struct HistoryData {
    float data[512];
};

struct ConstantData {
    matrix_float4x4 mvp;
    int drawStyle;
    simd_float3 light;
};
