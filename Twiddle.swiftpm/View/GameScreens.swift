import SwiftUI

// FIXME: 중복 요소 함수로 빼기
struct StartScreen: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        ZStack{
            Color.white
                .opacity(0.1)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .opacity(0.8)
            VStack {
                Image("TwiddleTitle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 500)
                    .padding()
                
                Button(action: {
                    gameManager.startGame()
                }) {
                    Image("StartButton") 
                        .resizable() 
                        .scaledToFit() 
                        .frame(width: 200) 
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct NextScreen: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        ZStack{
            Color.white
                .opacity(0.1)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .opacity(0.8)
            VStack {
                Text("Good Job!")
                    .font(.system(size: 100)) 
                    .fontWeight(.heavy)
                    .padding()
                    .shadow(radius: 10)
                
                Button(action: {
                    gameManager.goToNextStep()
                }) {
                    Image("NextButton") 
                        .resizable() 
                        .scaledToFit() 
                        .frame(width: 200) 
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}


struct GameClearScreen: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        ZStack{
            Color.white
                .opacity(0.1)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .opacity(0.8)
            VStack {
                Text("Game Cleared!")
                    .font(.system(size: 100)) 
                    .fontWeight(.heavy)
                    .padding()
                    .shadow(radius: 10)
                
                Button(action: {
                    gameManager.restartGame()
                }) {
                    Image("RestartButton") 
                        .resizable() 
                        .scaledToFit() 
                        .frame(width: 200) 
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}
