import SwiftUI

struct GameStepView: View {
    var frameHandler: FrameHandler = FrameHandler.shared
    @ObservedObject var gameManager: GameManager
    
    var geometry: GeometryProxy
    let step: Int
    
    // MARK: Step 1 - animation
    @State private var spriteIndex = 0
    @State private var shouldAnimate = false
    
    // MARK: Step 2 - spriteChange
    @State private var spriteIndexSecond = 0
    
    // MARK: countDown 관련 변수
    @State private var countdown = 3
    @State private var isCountingDown = true
    
    var body: some View{
        ZStack{
            if isCountingDown {
                ZStack{
                    Color.white
                        .opacity(0.1)
                        .ignoresSafeArea()
                        .background(.ultraThinMaterial)
                        .opacity(0.8)
                    VStack{
                        Text("\(gameManager.currentStep.instruction[0])")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                            .padding()
                        HStack(spacing: 50) {
                            gameManager.currentStep.handPoseSpritesA[spriteIndex]
                                .resizable()
                                .frame(width:150, height: 150)
                            ForEach((1...3).reversed(), id: \ .self) { number in
                                Text("\(number)")
                                    .font(.system(size: 100, weight: .bold))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .opacity(countdown == number ? 1.0 : 0.4)
                                    .transition(.scale)
                            }
                            gameManager.currentStep.handPoseSpritesB[spriteIndex]
                                .resizable()
                                .frame(width:150, height: 150)
                        }
                    }
                }
            }
            else{
                drawFingerPoints(fingers: frameHandler.fingerPoints, color: Color.orange)
                
                VStack {
                    Text("\(gameManager.currentStep.instruction[0])")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(radius: 10)
                        .padding()
                    
                    HStack{
                        gameManager.currentStep.handPoseSpritesA[spriteIndex]
                            .resizable()
                            .frame(width:150, height: 150)
                        Spacer()
                        gameManager.currentStep.handPoseSpritesB[spriteIndex]
                            .resizable()
                            .frame(width:150, height: 150)
                    }
                    .padding(.horizontal,80)
                    
                    Spacer()
                    HStack(spacing: -20) {
                        ForEach(0..<gameManager.currentStep.requiredCount, id: \.self) { index in
                            Image(index < frameHandler.completedGesture ? "HeartFull" : "HeartEmpty")
                                .resizable()
                                .frame(width: 100, height: 100)
                            
                        }
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .onAppear(){
            startCountdown()
            switch(gameManager.currentStepIndex)
            {
            case 0:
                playSpriteAnimation(repeatCount: 3)
            case 1:
                playAlternateSpriteAnimation(repeatCount: 4)
            case 2:
                playBounceSpriteAnimation()
            default:
                break
            }
            
        }
        .onChange(of: frameHandler.completedGesture) {
            AudioManager.shared.playSound(named: "heartGained")
            switch(gameManager.currentStepIndex)
            {
            case 0:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    playSpriteAnimation(repeatCount: 1)
                }
            case 1:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    spriteIndex += 1
                    spriteIndex = switchSprite(count: gameManager.currentStep.handPoseSpritesA.count)
                }
            case 2:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    spriteIndex += 1
                    if(spriteIndex == 4){
                        spriteIndex -= 1
                    }
                }
            default:
                break
            }
        }
    }
    
    @ViewBuilder
    private func drawFingerPoints(fingers: [CGPoint], color: Color) -> some View {
        let displayColor = fingers.isEmpty ? Color.clear : color
        
        ForEach(fingers, id: \.self) { point in
            Circle()
                .fill(displayColor)
                .frame(width: 10, height: 10)
                .position(x: point.x * geometry.size.width, y: point.y * geometry.size.height)
        }
    }
    
    // MARK: Countdown
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                withAnimation {
                    countdown -= 1
                }
            } else {
                timer.invalidate()
                withAnimation {
                    isCountingDown = false
                }
            }
        }
    }
    
    // MARK: Animation 관련
    private func playSpriteAnimation(repeatCount: Int) {
        shouldAnimate = true
        
        func animateCycle(count: Int) {
            if count == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    shouldAnimate = false
                }
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    spriteIndex = 1
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    spriteIndex = 0
                }
            }
            
            // 애니메이션 사이클이 끝난 후 0.8초 대기 후 반복
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                animateCycle(count: count - 1)
            }
        }
        
        animateCycle(count: repeatCount)
    }
    
    private func switchSprite(count : Int) -> Int {
        return spriteIndex % count
    }
    
    private func playAlternateSpriteAnimation(repeatCount: Int) {
        shouldAnimate = true
        
        func animateCycle(count: Int) {
            if count == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    shouldAnimate = false
                }
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    spriteIndex = (spriteIndex == 0) ? 1 : 0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    spriteIndex = (spriteIndex == 0) ? 1 : 0
                }
            }
            
            // 0.8초 후 다음 사이클 실행
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                animateCycle(count: count - 1)
            }
        }
        
        animateCycle(count: repeatCount)
    }
    
    private func playBounceSpriteAnimation() {
        let sequence = [0, 1, 2, 3, 4, 3, 2, 1, 0] 
        var index = 0
        
        func animateStep() {
            if index < sequence.count {
                withAnimation(.easeInOut(duration: 0.1)) {
                    spriteIndex = sequence[index]
                }
                
                index += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateStep()
                }
            }
        }
        
        animateStep()
    }
}
