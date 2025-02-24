import CoreGraphics

struct HandPoints {
    var wrist: CGPoint?
    var thumbTip: CGPoint?
    var indexTip: CGPoint?
    var middleTip: CGPoint?
    var ringTip: CGPoint?
    var littleTip: CGPoint?
}

class HandGestureProcessor {
    // MARK: 싱글톤
    static let shared = HandGestureProcessor()
    
    enum State {
        case fist            // step 1
        case open            // step 1
        case ApinkyBthumb    // step 2
        case AthumbBpinky    // step 2
        case FUUUU           // step 3
        case FFUUU           // step 3
        case FFFUU           // step 3
        case FFFFU           // step 3
        case FFFFF           // step 3
        case unknown         
    }
    
    var didChangeStateClosure: ((State) -> Void)?
    
    private var state = State.unknown {
        didSet{
            didChangeStateClosure?(state)
        }
    }
    
    //MARK: 제스처 감지 변수
    //TODO: 손 거리가 일정 이상 멀어지면 가까이 오라는 Alert 필요
    private let FistMaxDistance: CGFloat
    private var fistEvidenceCounter = 0
    private var fistCount: Int = 0
    private var switchEvidenceCounter = 0
    private var switchCount: Int = 0
    private var foldingCount: Int = 0
    
    //MARK: 제스처별 감지되기 위해 유지되어야 하는 최소 프레임 수
    private let evidenceCounterStateTrigger: Int
    
    init(FistMaxDistance: CGFloat = 0.15, evidenceCounterStateTrigger: Int = 3) {
        self.FistMaxDistance = FistMaxDistance
        self.evidenceCounterStateTrigger = evidenceCounterStateTrigger
    }
    
    // MARK: restart 시 실행
    func reset(){
        fistCount = 0
        switchCount = 0
        foldingCount = 0
    }
    
    // MARK: Step 1 - 주먹쥐는 카운트
    func checkFistCount(hand : HandPoints) -> Int
    {
        guard let distance1 = hand.thumbTip?.distance(from: hand.wrist!),
              let distance2 = hand.indexTip?.distance(from: hand.wrist!),
              let distance3 = hand.middleTip?.distance(from: hand.wrist!),
              let distance4 = hand.ringTip?.distance(from: hand.wrist!),
              let distance5 = hand.littleTip?.distance(from: hand.wrist!) else {return fistCount}
        
        if(distance1 < FistMaxDistance && distance2 < FistMaxDistance && distance3 < FistMaxDistance &&
        distance4 < FistMaxDistance && distance5 < FistMaxDistance) {
            fistEvidenceCounter += 1
            
            if(state != .fist && fistEvidenceCounter >= evidenceCounterStateTrigger){
                state = .fist
                fistCount += 1
            }
        }else if(distance1 > 0.17 && distance2 > 0.3 && distance3 > 0.3 && distance4 > 0.3 && distance5 > 0.2 ){
            if(state != .open){
                state = .open
            }
        }
        return fistCount
    }
    
    // MARK: Step 2 - thumb & pinky
    func checkPinkyThumbCount(handA: HandPoints, handB: HandPoints) -> Int {
        let hand1: HandPoints
        let hand2: HandPoints
        
        if let wristA = handA.wrist, let wristB = handB.wrist {
            if wristA.x < wristB.x {
                hand1 = handA  // 왼손
                hand2 = handB  // 오른손
            } else {
                hand1 = handB  // 왼손
                hand2 = handA  // 오른손
            }
        } else {
            return switchCount
        }
        
        guard let distanceA1 = hand1.thumbTip?.distance(from: hand1.wrist!) else { return switchCount }
        guard let distanceA5 = hand1.littleTip?.distance(from: hand1.wrist!) else { return switchCount }
        
        guard let distanceB1 = hand2.thumbTip?.distance(from: hand2.wrist!) else { return switchCount }
        guard let distanceB5 = hand2.littleTip?.distance(from: hand2.wrist!) else { return switchCount }
 
        if distanceA5 > 0.1 && distanceB1 > 0.17 {
            if state != .ApinkyBthumb && switchCount % 2 == 0 {
                switchEvidenceCounter += 1
                if switchEvidenceCounter >= evidenceCounterStateTrigger {
                    state = .ApinkyBthumb
                    switchCount += 1
                    switchEvidenceCounter = 0 
                }
            } else {
                switchEvidenceCounter = 0  
            }
        } else if distanceB5 > 0.1 && distanceA1 > 0.17 {
            if state != .AthumbBpinky && switchCount % 2 == 1 {
                switchEvidenceCounter += 1
                if switchEvidenceCounter >= evidenceCounterStateTrigger {
                    state = .AthumbBpinky
                    switchCount += 1
                    switchEvidenceCounter = 0  
                }
            } else {
                switchEvidenceCounter = 0  
            }
        } else {
            switchEvidenceCounter = 0  
        }
        return switchCount
    }
    
    // MARK: Step 3 - foldingOnebyOne
    func checkFoldOnebyOneCount(handA: HandPoints, handB: HandPoints) -> Int {
        let fingerStates: [Bool] = [
            handA.thumbTip?.distance(from: handA.wrist!) ?? 1.0 < FistMaxDistance &&
            handB.thumbTip?.distance(from: handB.wrist!) ?? 1.0 < FistMaxDistance,
            
            handA.indexTip?.distance(from: handA.wrist!) ?? 1.0 < FistMaxDistance &&
            handB.indexTip?.distance(from: handB.wrist!) ?? 1.0 < FistMaxDistance,
            
            handA.middleTip?.distance(from: handA.wrist!) ?? 1.0 < FistMaxDistance &&
            handB.middleTip?.distance(from: handB.wrist!) ?? 1.0 < FistMaxDistance,
            
            handA.ringTip?.distance(from: handA.wrist!) ?? 1.0 < FistMaxDistance &&
            handB.ringTip?.distance(from: handB.wrist!) ?? 1.0 < FistMaxDistance,
            
            handA.littleTip?.distance(from: handA.wrist!) ?? 1.0 < FistMaxDistance &&
            handB.littleTip?.distance(from: handB.wrist!) ?? 1.0 < FistMaxDistance
        ]
        
        // 현재 몇 개의 손가락이 접혀 있는지 계산
        let currentFoldState = fingerStates.filter { $0 }.count
        
        // 이전보다 +1 증가할 때만 foldingCompletedCount를 올림
        if currentFoldState == foldingCount + 1 {
            foldingCount = currentFoldState
        }
        
        // 상태 변경
        switch currentFoldState {
        case 1: state = .FUUUU
        case 2: state = .FFUUU
        case 3: state = .FFFUU
        case 4: state = .FFFFU
        case 5: state = .FFFFF
        default: break
        }
        
        return foldingCount
    }
}

extension CGPoint {
    func distance(from point: CGPoint) -> CGFloat{
        return hypot(point.x - x, point.y - y)    // hypot: 피타고라스 정리로 두 점 사이 빗변 길이 구하기
    }
}
