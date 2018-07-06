import UIKit
import MetalKit
import AVFoundation

let history = History()
var isTouched:Bool = false

class ViewController: UIViewController {
    var renderer: Renderer!
    var audioInput: TempiAudioInput!
    
    @IBOutlet var metalView: MTKView!
    @IBOutlet var spectralView: SpectralView!
    @IBOutlet var scaleSider: UISlider!
    @IBOutlet var smoothSider: UISlider!
    @IBOutlet var baseIndexSlider: UISlider!
    @IBOutlet var hScaleSlider: UISlider!
    @IBOutlet var hColorSlider: UISlider!
    
    @IBAction func setAmbientPressed(_ sender: UIButton) { spectralView.setAmbient() }
    @IBAction func scaleSliderChanged(_ sender: UISlider) { spectralView.setScale(sender.value) }
    @IBAction func smoothSliderChanged(_ sender: UISlider) { spectralView.setSmooth(sender.value) }
    
    @IBAction func baseIndexSliderChanged(_ sender: UISlider) {
        baseIndex = Int(baseIndexSlider.value * Float(FFT_SIZE))
        if baseIndex >= FFT_SIZE - HISTORY_SIZE { baseIndex = FFT_SIZE - HISTORY_SIZE - 1 }
    }
    
    @IBAction func hScaleSliderChanged(_ sender: UISlider) { history.setScale(sender.value) }
    @IBAction func hColorSliderChanged(_ sender: UISlider) { history.setColor(sender.value) }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = metalView else { fatalError("View of Gameview controller is not an MTKView") }
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else { fatalError("Metal is not supported") }
        
        metalView.device = defaultDevice
        metalView.backgroundColor = UIColor.clear
        
        guard let newRenderer = Renderer(metalKitView: metalView) else { fatalError("Renderer cannot be initialized") }
        renderer = newRenderer
        renderer.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
        metalView.delegate = renderer
        
        let audioInputCallback: TempiAudioInputCallback = { (timeStamp, numberOfFrames, samples) -> Void in
            self.gotSomeAudio(timeStamp: Double(timeStamp), numberOfFrames: Int(numberOfFrames), samples: samples)
        }
        
        history.initialize()
        spectralView.setScale(0.5)
        spectralView.setSmooth(0.5)
        
        audioInput = TempiAudioInput(audioInputCallback: audioInputCallback, sampleRate: 44100, numberOfChannels: 1)
        audioInput.startRecording()
        
        Timer.scheduledTimer(withTimeInterval:1, repeats:false) { timer in self.timerKick() }
    }
    
    @objc func timerKick() { spectralView.setAmbient() }

    //MARK: -
    
    func gotSomeAudio(timeStamp: Double, numberOfFrames: Int, samples: [Float]) {
        let fft = TempiFFT(withSize: numberOfFrames, sampleRate: 44100.0)
        fft.windowType = TempiFFTWindowType.hanning
        fft.fftForward(samples)
        
        fft.calculateLinearBands(minFrequency: 0, maxFrequency: fft.nyquistFrequency, numberOfBands:FFT_SIZE)
        
        tempi_dispatch_main { () -> () in
            self.spectralView.fft = fft
            self.spectralView.setNeedsDisplay()
        }
        
        history.update()
    }
    
    //MARK: -
    
    var startTranslation = float3()
    var startRotation = CGPoint()
    
    func parseTranslation(_ pt:CGPoint) {
        let scale:Float = 0.01
        translation.x += Float(pt.x - CGFloat(startTranslation.x)) * scale
        translation.y -= Float(pt.y - CGFloat(startTranslation.y)) * scale
    }
    
    func parseRotation(_ pt:CGPoint) {
        let sz = metalView.bounds.size
        let xc = CGFloat(sz.width/2)
        let yc = CGFloat(sz.height/2)
        var t = pt
        let scale:CGFloat = 0.05
        t.x *= scale
        t.y *= scale
        
        arcBall.mouseDown(CGPoint(x:xc, y:yc))
        arcBall.mouseMove(CGPoint(x:xc - t.x, y:yc - t.y))
    }
    
    var numberPanTouches:Int = 0
    
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        let pt = sender.translation(in: self.view)
        if sender.state == .began {
            startTranslation = translation
            startRotation = pt
            isTouched = true
        }
        else {
            let count = sender.numberOfTouches
            if count == 0 { numberPanTouches = 0 }  else if count > numberPanTouches { numberPanTouches = count }
            
            switch sender.numberOfTouches {
            case 1 : if numberPanTouches < 2 { parseRotation(pt) } // prevent rotation after releasing translation
            case 2 : parseTranslation(pt)
            default : break
            }
        }
        
        if sender.state == .ended {
            isTouched = false
        }
    }
    
    var startZoom:Float = 0
    
    @IBAction func pinchGesture(_ sender: UIPinchGestureRecognizer) {
        let min:Float = 1
        let max:Float = 300
        if sender.state == .began { startZoom = translation.z  }
        translation.z = fClamp(startZoom / Float(sender.scale),min,max)
        
        if sender.state == .began {
            isTouched = true
        }
        if sender.state == .ended {
            isTouched = false
        }
    }
    
    override var prefersStatusBarHidden: Bool { return true }
}

func fClamp(_ v:Float, _ min:Float, _ max:Float) -> Float {
    if v < min { return min }
    if v > max { return max }
    return v
}


