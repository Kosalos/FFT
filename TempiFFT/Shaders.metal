#include <metal_stdlib>
#include <simd/simd.h>
#import "Shaders.h"

using namespace metal;

struct Transfer {
    float4 position [[position]];
    float4 color;
};

vertex Transfer texturedVertexShader
(
 device TVertex* vData [[ buffer(0) ]],
 constant ConstantData& constantData [[ buffer(1) ]],
 unsigned int vid [[ vertex_id ]])
{
    Transfer out;
    TVertex v = vData[vid];
    
    out.color = v.color;
    out.position = constantData.mvp * float4(v.pos, 1.0);
    
    return out;
}

fragment float4 texturedFragmentShader
(
 Transfer data [[stage_in]],
 texture2d<float> tex2D [[texture(0)]],
 sampler sampler2D [[sampler(0)]])
{
    return data.color;
}

//////////////////////////////////////////////////////

kernel void addHistory
(
 device TVertex* vData [[ buffer(0) ]],
 constant ConstantData &cd[[ buffer(1) ]],
 uint2 p [[thread_position_in_grid]])
{
    //    float center = -float(SGSPAN) / 2;
    //    device TVertex &t = sgrid.data[p.x][p.y][p.z];
    //
    //    t.pos = cd.pos;
    //    t.pos.x += center + float(p.x);
    //    t.pos.y += center + float(p.y);
    //    t.pos.z += center + float(p.z);
}

