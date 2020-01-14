import UIKit
import Metal

var yScale:Float = 0.353
var colorScale:Float = 0.04

class History {
    let width:Int = HISTORY_SIZE
    let height:Int = 150
    let fw = Float(FFT_SIZE)
    
    var fft: TempiFFT! = nil

    var vBuffer: MTLBuffer?
    var iBufferL: MTLBuffer?
    var iBufferT: MTLBuffer?
    var vData = Array<TVertex>()    // vertices
    var iDataL = Array<UInt16>()    // indices of line segments
    var iDataT = Array<UInt16>()    // indices of triangles
    var color:simd_float4 = simd_float4(1,1,1,1)
    var drawStyle:UInt8 = 1
    var meshStyle:Int = 0
    
    init() {
    }
    
    var pace:Int = 0
    var isBusy:Bool = false
    
    func addHistory() {

        if isTouched { return }
        pace += 1
        if pace < 2 { return }
        pace = 0
        
        if isBusy { return }
        isBusy = true

        var index:Int = 0
        for _ in 0 ..< height-1 {
            for _ in 0 ..< width {
                let v = vData[index + width]
                vData[index].pos.z = v.pos.z // vData[index + width].pos.z
                vData[index].color = v.color //simd_float4(0.3,0.4,0.5,1) //vData[index + width].color
                index += 1
            }
        }

        for i in 0 ..< width {
            let dIndex = i + baseIndex
            vData[index].pos.z = Float(smoothData[dIndex]) * yScale

            var cIndex:Int = Int(  powf(abs(Float(smoothData[dIndex])),1 + colorScale) )
            cIndex = cIndex % 256
            let cc:simd_float3 = colorMap[255 - cIndex]

            vData[index].color.x = cc.x
            vData[index].color.y = cc.y
            vData[index].color.z = cc.z
            index += 1
        }

        vBuffer?.contents().copyMemory(from: &vData, byteCount:vData.count  * MemoryLayout<TVertex>.stride)
        isBusy = false
    }
    
    func setScale(_ ratio:Float) { yScale = 0.01 + ratio * 0.5 }
    func setColor(_ ratio:Float) { colorScale = ratio }

    func initialize() {
        generate()
    }
    
    func update() {
    }
    
    //MARK: -
    
    func generate() {
        vData.removeAll()
        iDataL.removeAll()
        iDataT.removeAll()
        
        for y in 0 ..< height {
            for x in 0 ..< width {
                var v = TVertex()
                v.pos.x = Float(x - width/2)
                v.pos.y = Float(y - height/2)
                v.pos.z = Float(0)
                
                v.nrm = normalize(v.pos)
                
                v.txt.x = Float(x) / Float(width)
                v.txt.y = Float(1) - Float(y) / Float(height)
                
                v.drawStyle = drawStyle
                v.color = simd_float4(0,0,0,1)
                
                vData.append(v)
            }
        }
        
        // Line index buffer ---------------
        for y in 0 ..< height-1 {
            for x in 0 ..< width-1 {
                iDataL.append(UInt16(y*width+x))
                iDataL.append(UInt16(y*width+x+1))
                
                iDataL.append(UInt16(y*width+x))
                iDataL.append(UInt16((y+1)*width+x))
            }
        }
        
        // Triangle index buffer -----------
        for y in 0 ..< height-1 {
            for x in 0 ..< width-1 {
                let p1 = UInt16(x + y * width)
                let p2 = UInt16(x + 1 + y * width)
                let p3 = UInt16(x + (y+1) * width)
                let p4 = UInt16(x + 1 + (y+1) * width)
                
                iDataT.append(p1)
                iDataT.append(p3)
                iDataT.append(p2)
                
                iDataT.append(p2)
                iDataT.append(p3)
                iDataT.append(p4)
            }
        }
        
        vBuffer  = gDevice?.makeBuffer(bytes: vData,  length: vData.count  * MemoryLayout<TVertex>.size, options: MTLResourceOptions())
        iBufferL = gDevice?.makeBuffer(bytes: iDataL, length: iDataL.count * MemoryLayout<UInt16>.size,  options: MTLResourceOptions())
        iBufferT = gDevice?.makeBuffer(bytes: iDataT, length: iDataT.count * MemoryLayout<UInt16>.size,  options: MTLResourceOptions())
    }
    
    func render(_ renderEncoder:MTLRenderCommandEncoder) {
        if vData.count == 0 { return }
        
        renderEncoder.setVertexBuffer(vBuffer, offset: 0, index: 0)
        
        if drawStyle == 1  {
            renderEncoder.drawIndexedPrimitives(type: .triangle,  indexCount: iDataT.count, indexType: MTLIndexType.uint16, indexBuffer: iBufferT!, indexBufferOffset:0)
        }
        else {
            renderEncoder.drawIndexedPrimitives(type: .line,  indexCount: iDataL.count, indexType: MTLIndexType.uint16, indexBuffer: iBufferL!, indexBufferOffset:0)
        }
    }
}

