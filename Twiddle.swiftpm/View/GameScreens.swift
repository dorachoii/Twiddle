import SwiftUI

// FIXME: 중복 요소 함수로 빼기
struct StartScreen: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        VStack {
            Text("Twiddle")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Start") {
                gameManager.startGame()
            }
            .font(.title)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct PauseScreen: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        VStack {
            Text("Paused")
                .font(.largeTitle)
            
            Button("Resume") {
                gameManager.startGame()
            }
            .padding()
        }
    }
}

struct GameClearScreen: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        VStack {
            Text("Game Cleared!")
                .font(.largeTitle)
            
            Button("Restart") {
                gameManager.restartGame()
            }
            .padding()
        }
    }
}
