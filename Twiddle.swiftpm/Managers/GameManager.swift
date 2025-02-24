import SwiftUI

enum GameState {
    case start
    case playing(step: Int)
    case next
    case gameCleared
}

struct GameStep {
    let handPoseType: [HandGestureProcessor.State]
    let instruction: [String]
    let requiredCount: Int
    let handPoseSpritesA: [Image]
    let handPoseSpritesB: [Image]
}

let gameSteps: [GameStep] = [
    GameStep(
        handPoseType: [.fist],
        instruction: ["Make a fist and then open your hand!",""],
        requiredCount: 5,
        handPoseSpritesA: [Image("1_A0"),Image("1_A1")],
        handPoseSpritesB: [Image("1_B0"),Image("1_B1")]
    ),
    GameStep(
        handPoseType: [.fist],
        instruction: ["Switch between extending your thumb and pinky finger!",""],
        requiredCount: 6,
        handPoseSpritesA: [Image("2_A0"),Image("2_A1")],
        handPoseSpritesB: [Image("2_B0"),Image("2_B1")]
    ),
    GameStep(
        handPoseType: [.fist],
        instruction: ["Fold your fingers one by one!","Unfold your fingers one by one!"],
        requiredCount: 10,
        handPoseSpritesA: [Image("3_A0"),Image("3_A1"),Image("3_A2"),Image("3_A3"),Image("3_A4")],
        handPoseSpritesB: [Image("3_B0"),Image("3_B1"),Image("3_B2"),Image("3_B3"),Image("3_B4")]
    )
]

class GameManager: ObservableObject {
    @Published var gameState: GameState = .start
    @Published var currentStepIndex = 0
    @Published var currentStep: GameStep = gameSteps[0]
    
    func startGame() {
        gameState = .playing(step: currentStepIndex + 1)
        FrameHandler.shared.gameManager = self
        AudioManager.shared.playSound(named: "timer")
    }
    
    func nextStep() {
        if currentStepIndex < gameSteps.count - 1 {
            gameState = .next
        } else {
            gameState = .gameCleared  // 마지막 스텝 완료 시 게임 클리어
        }
    }
    
    func goToNextStep() {
        if currentStepIndex < gameSteps.count - 1 {
            currentStepIndex += 1
            currentStep = gameSteps[currentStepIndex]
            gameState = .playing(step: currentStepIndex + 1)
            AudioManager.shared.playSound(named: "timer")
        } else {
            gameState = .gameCleared
        }
    }
    
    func gameCleared() {
        gameState = .gameCleared
    }
    
    func restartGame() {
        HandGestureProcessor.shared.reset()
        currentStepIndex = 0
        gameState = .start
    }
}
