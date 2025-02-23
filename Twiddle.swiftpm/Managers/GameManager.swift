import SwiftUI

enum GameState {
    case start
    case playing(step: Int)
    case pause
    case gameCleared
}

class GameManager: ObservableObject {
    @Published var gameState: GameState = .start
    
    func startGame() {
        gameState = .playing(step: 1)
    }
    
    func nextStep() {
        if case .playing(let step) = gameState, step < 3 {
            gameState = .playing(step: step + 1)
        } else {
            gameCleared()
        }
    }
    
    func pauseGame() {
        gameState = .pause
    }
    
    func gameCleared() {
        gameState = .gameCleared
    }
    
    func restartGame() {
        gameState = .start
    }
}
