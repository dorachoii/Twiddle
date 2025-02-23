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
    enum State {
        case fist
        case open
        case unknown
    }
    
    var didChangeStateClosure: ((State) -> Void)?
    
    private var state = State.unknown {
        didSet{
            didChangeStateClosure?(state)
        }
    }
    
    //MARK: 제스처 감지 변수
    //TODO: 손 크기가 일정하게 유지되도록 거리를 재고 있어야 함.
    private let FistMaxDistance: CGFloat
    private var fistEvidenceCounter = 0
    private var fistCount: Int = 0
    
    //MARK: 제스처별 감지되기 위해 유지되어야 하는 최소 프레임 수
    private let evidenceCounterStateTrigger: Int
    
    init(FistMaxDistance: CGFloat = 0.15, evidenceCounterStateTrigger: Int = 3) {
        self.FistMaxDistance = FistMaxDistance
        self.evidenceCounterStateTrigger = evidenceCounterStateTrigger
    }
    
    // MARK: 주먹쥐는 카운트
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
            print("현재 상태는 \(state)")
        }
        return fistCount
    }
}

extension CGPoint {
    func distance(from point: CGPoint) -> CGFloat{
        return hypot(point.x - x, point.y - y)    // hypot: 피타고라스 정리로 두 점 사이 빗변 길이 구하기
    }
}
