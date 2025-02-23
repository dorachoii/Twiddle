import SwiftUI

struct GameView: View {
    @StateObject private var gameManager = GameManager()
    @ObservedObject var frameHandler: FrameHandler
    
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                FrameView(frameHandler: frameHandler)
                
                switch gameManager.gameState {
                case .start:
                    StartScreen(gameManager: gameManager)
                case .playing(let step):
                    GameStepView(frameHandler: frameHandler, geometry: geometry, step: step)
                case .pause:
                    PauseScreen(gameManager: gameManager)
                case .gameCleared:
                    GameClearScreen(gameManager: gameManager)
                }
            }
            //.animation(.easeInOut, value: gameManager.gameState)
        }
    }
}
