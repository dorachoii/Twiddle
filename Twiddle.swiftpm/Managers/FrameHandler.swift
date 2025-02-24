import AVFoundation
import CoreImage
import Vision

class FrameHandler: NSObject, ObservableObject {
    // MARK: 싱글톤
    static let shared = FrameHandler()
    
    // MARK: AVFoundation 관련
    @Published var frame: CGImage?    // videoOutput 담을 변수
    private var permissionGranted = true
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")    // 백그라운드에서도 가능
    private let context = CIContext()    // videoOutput 변환 과정에서 필요한 변수
    
    // MARK: HandPose 관련
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var gestureProcessor = HandGestureProcessor()
    @Published var fingerPoints: [CGPoint] = []
    @Published var completedGesture: Int = 0
    
    // MARK: GameManager 할당 위한 변수
    var gameManager: GameManager?
    
    // MARK: 가장 처음 실행할 것들
    override init() {
        // MARK: AVFoundation 관련
        super.init()
        self.checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
        
        //MARK: Handpose 관련
        handPoseRequest.maximumHandCount = 2
    }
    
    // MARK: 권한 체크
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: 
            self.permissionGranted = true
        case .notDetermined: 
            self.requestPermission()
        default:
            self.permissionGranted = false
        }
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
        }
    }
    
    // MARK: captureSession - 카메라 장치 및 데이터 흐름 관리
    func setupCaptureSession() {
        let videoOutput = AVCaptureVideoDataOutput()
        
        guard permissionGranted else { return }
        
        // MARK: Input - mac 전면 카메라
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video, position: .front) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        // MARK: Output - sampleBuffer에 받아서, avcapturevideodataoutput으로 변환해와야 한다.
        // 그 대리자를 나로 설정하고 extension에서 동작 추가
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        
        videoOutput.connection(with: .video)?.isVideoMirrored = true
    }
    
    // MARK: handPose 1 - fist
    func detectHandPoseA(handA: HandPoints, handB: HandPoints)
    {
        if let gameManager = gameManager {
            self.completedGesture = gestureProcessor.checkFistCount(hand: handA)
            if self.completedGesture >= gameManager.currentStep.requiredCount{
                DispatchQueue.main.async{
                    self.completedGesture = 0
                    gameManager.nextStep()
                }
            }
        }
    }
    
    // MARK: handPose 2 - ThumbPinky
    func detectHandPoseA(handB: HandPoints, handB: HandPoints)
    {
        if let gameManager = gameManager {
            self.completedGesture = gestureProcessor.checkPinkyThumbCount(handA: handA, handB: handB)
            if self.completedGesture >= gameManager.currentStep.requiredCount{
                DispatchQueue.main.async{
                    self.completedGesture = 0
                    gameManager.nextStep()
                }
            }
        }
    }
    
    // MARK: handPose 3 - Fold & Unfold
    func detectHandPose3(handA: HandPoints, handB: HandPoints)
    {
        if let gameManager = gameManager {
            self.completedGesture = gestureProcessor.checkFoldOnebyOneCount(handA: handA, handB: handB)
            if self.completedGesture >= gameManager.currentStep.requiredCount{
                DispatchQueue.main.async{
                    self.completedGesture = 0
                    gameManager.nextStep()
                }
            }
        }
    }
}


extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // MARK: AVFoundation 관련 View에 표시하기 위한 image 반환
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        // All UI updates should be/ must be performed on the main queue.
        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
        
        // MARK: HandPose 관련 위치 담을 변수
        var thumbTipA: CGPoint
        var indexTipA: CGPoint
        var middleTipA: CGPoint
        var ringTipA: CGPoint
        var littleTipA: CGPoint
        
        var thumbTipB: CGPoint
        var indexTipB: CGPoint
        var middleTipB: CGPoint
        var ringTipB: CGPoint
        var littleTipB: CGPoint
        
        var wristA: CGPoint
        var wristB: CGPoint
        
        // MARK: detectHandPose 함수 비동기 실행
        defer {
            DispatchQueue.main.async{
                if let gameManager = self.gameManager{
                    switch(gameManager.currentStepIndex){
                    case 0:
                        self.detectHandPoseA(handA: HandPoints(wrist: wristA, thumbTip: thumbTipA, indexTip: indexTipA, middleTip: middleTipA,ringTip: ringTipA,littleTip: littleTipA), handB: HandPoints(wrist: wristB, thumbTip: thumbTipB, indexTip: indexTipB, middleTip: middleTipB, ringTip: ringTipB, littleTip: littleTipB))
                    case 1:
                        self.detectHandPoseB(handA: HandPoints(wrist: wristA, thumbTip: thumbTipA, indexTip: indexTipA, middleTip: middleTipA,ringTip: ringTipA,littleTip: littleTipA), handB: HandPoints(wrist: wristB, thumbTip: thumbTipB, indexTip: indexTipB, middleTip: middleTipB, ringTip: ringTipB, littleTip: littleTipB))
                    case 2:
                        self.detectHandPoseC(handA: HandPoints(wrist: wristA, thumbTip: thumbTipA, indexTip: indexTipA, middleTip: middleTipA,ringTip: ringTipA,littleTip: littleTipA), handB: HandPoints(wrist: wristB, thumbTip: thumbTipB, indexTip: indexTipB, middleTip: middleTipB, ringTip: ringTipB, littleTip: littleTipB))
                    default:
                        break
                    }
                }
            }
        }
        
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            guard let results = handPoseRequest.results, results.count > 1 else {
                DispatchQueue.main.async { [unowned self] in
                    self.fingerPoints.removeAll()
                }
                return }
            
            let firstHand = results[0]
            let secondHand = results[1]
            
            let thumbPointsA = try firstHand.recognizedPoints(.thumb)
            let indexFingerPointsA = try firstHand.recognizedPoints(.indexFinger)
            let middleFingerPointsA = try firstHand.recognizedPoints(.middleFinger)
            let ringFingerPointsA = try firstHand.recognizedPoints(.ringFinger)
            let littleFingerPointsA = try firstHand.recognizedPoints(.littleFinger)
            
            let thumbPointsB = try secondHand.recognizedPoints(.thumb)
            let indexFingerPointsB = try secondHand.recognizedPoints(.indexFinger)
            let middleFingerPointsB = try secondHand.recognizedPoints(.middleFinger)
            let ringFingerPointsB = try secondHand.recognizedPoints(.ringFinger)
            let littleFingerPointsB = try secondHand.recognizedPoints(.littleFinger)
            
            let allPointsA = try firstHand.recognizedPoints(.all)
            let allPointsB = try secondHand.recognizedPoints(.all)
            
            guard let thumbTipPointA = thumbPointsA[.thumbTip],
                  let indexFingerTipPointA = indexFingerPointsA[.indexTip],
                  let middleFingerTipPointA = middleFingerPointsA[.middleTip],
                  let ringFingerTipPointA = ringFingerPointsA[.ringTip],
                  let littleFingerTipPointA = littleFingerPointsA[.littleTip] else { return }
            
            guard let thumbTipPointB = thumbPointsB[.thumbTip],
                  let indexFingerTipPointB = indexFingerPointsB[.indexTip],
                  let middleFingerTipPointB = middleFingerPointsB[.middleTip],
                  let ringFingerTipPointB = ringFingerPointsB[.ringTip],
                  let littleFingerTipPointB = littleFingerPointsB[.littleTip] else { return }
            
            guard let wristPointA = allPointsA[.wrist],
                  let wristPointB = allPointsB[.wrist] else { return }
            
            // 불확실한 값은 버린다
            guard thumbTipPointA.confidence > 0.3 && indexFingerTipPointA.confidence > 0.3
                    && middleFingerTipPointA.confidence > 0.3 && ringFingerTipPointA.confidence > 0.3 && littleFingerTipPointA.confidence > 0.3 else {return}
            
            guard thumbTipPointB.confidence > 0.3 && indexFingerTipPointB.confidence > 0.3
                    && middleFingerTipPointB.confidence > 0.3 && ringFingerTipPointB.confidence > 0.3 && littleFingerTipPointB.confidence > 0.3 else {return}
            
            guard wristPointA.confidence > 0.3 && wristPointB.confidence > 0.3 else {return}
            
            // 읽어온 값을 대입시켜줌 : 이 좌표 부분을 개선하는 코드가있나봄
            thumbTipA = CGPoint(x: thumbTipPointA.location.x, y: 1 - thumbTipPointA.location.y)
            indexTipA = CGPoint(x: indexFingerTipPointA.location.x, y: 1 - indexFingerTipPointA.location.y)
            middleTipA = CGPoint(x: middleFingerTipPointA.location.x, y: 1 - middleFingerTipPointA.location.y)
            ringTipA = CGPoint(x: ringFingerTipPointA.location.x, y: 1 - ringFingerTipPointA.location.y)
            littleTipA = CGPoint(x: littleFingerTipPointA.location.x, y: 1 - littleFingerTipPointA.location.y)
            
            thumbTipB = CGPoint(x: thumbTipPointB.location.x, y: 1 - thumbTipPointB.location.y)
            indexTipB = CGPoint(x: indexFingerTipPointB.location.x, y: 1 - indexFingerTipPointB.location.y)
            middleTipB = CGPoint(x: middleFingerTipPointB.location.x, y: 1 - middleFingerTipPointB.location.y)
            ringTipB = CGPoint(x: ringFingerTipPointB.location.x, y: 1 - ringFingerTipPointB.location.y)
            littleTipB = CGPoint(x: littleFingerTipPointB.location.x, y: 1 - littleFingerTipPointB.location.y)
            
            wristA = CGPoint(x: wristPointA.location.x, y: 1 - wristPointA.location.y)
            wristB = CGPoint(x: wristPointB.location.x, y: 1 - wristPointB.location.y)
            
            let points = [thumbTipA, indexTipA, middleTipA, ringTipA, littleTipA,thumbTipB, indexTipB, middleTipB, ringTipB, littleTipB, wristA, wristB]
            
            // MARK: AVFoundation 관련
            // All UI updates should be/ must be performed on the main queue.
            DispatchQueue.main.async { [unowned self] in
                self.fingerPoints = points
            }
        }catch{
            // FIXME: 일단 보류
            
        }
    }
    
    
    // MARK: sample buffer에서 frame 읽어오기 위한 변환 과정
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return cgImage
    }
}
