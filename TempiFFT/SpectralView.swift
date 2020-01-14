import UIKit

let FFT_SIZE:Int = 512
let HISTORY_SIZE:Int = 128

var baseIndex = Int()

var ambientData = Array(repeating:CGFloat(), count:FFT_SIZE)
var smoothData = Array(repeating:CGFloat(), count:FFT_SIZE)

var scale:CGFloat = 1.4
var smooth:CGFloat = 6.4

class SpectralView: UIView {
    var fft: TempiFFT!
    
    func setAmbient() {
        for i in 0 ..< FFT_SIZE {
            ambientData[i] = smoothData[i]
        }
    }
    
    func setScale(_ ratio:Float) {
        scale = CGFloat(1 + ratio * 3)
    }
    
    func setSmooth(_ ratio:Float) {
        smooth = CGFloat(1 + ratio * 20)
    }
    
    func updateSmoothedData() {
        for i in 0 ..< FFT_SIZE {
            let magnitude = fft.magnitudeAtBand(i)
            let magnitudeDB = TempiFFT.toDB(magnitude)
            let y = CGFloat(magnitudeDB) * scale
            
            smoothData[i] = (smoothData[i] * (smooth - 1.0) + y) / smooth
        }
    }

    override func draw(_ rect: CGRect) {
        if fft == nil { return }
        
        updateSmoothedData()
        history.addHistory()
        
        let viewWidth = bounds.width
        let viewHeight = bounds.height
        
        let context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(UIColor.white.cgColor)
        

        let xScale = viewWidth / CGFloat(FFT_SIZE)
        var x:CGFloat = 0.0

        for i in 0 ..< FFT_SIZE {
            let yc:CGFloat = bounds.height / 2
            let y = yc - (smoothData[i] - ambientData[i]) * scale

            context.beginPath()
            context.move(to: CGPoint(x:x, y:yc))
            context.addLine(to: CGPoint(x:x, y:y))
            context.strokePath()
            
            x += xScale
        }
        
        context.setStrokeColor(UIColor.yellow.cgColor)
        x = CGFloat(baseIndex) * xScale
        context.beginPath()
        context.move(to: CGPoint(x:x, y:0))
        context.addLine(to: CGPoint(x:x, y:viewHeight))
        context.strokePath()
        x = CGFloat(baseIndex + HISTORY_SIZE) * xScale
        context.beginPath()
        context.move(to: CGPoint(x:x, y:0))
        context.addLine(to: CGPoint(x:x, y:viewHeight))
        context.strokePath()
    }
}
