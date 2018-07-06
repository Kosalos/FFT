#pragma once

#include <simd/simd.h>
#include <simd/base.h>

struct TVertex {
    vector_float3 pos;
    vector_float3 nrm;
    vector_float2 txt;
    vector_float4 color;
    unsigned char drawStyle;
};

struct HistoryData {
    float data[512];
};

struct ConstantData {
    matrix_float4x4 mvp;
    int drawStyle;
    vector_float3 light;
};
