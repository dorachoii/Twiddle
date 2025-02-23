import SwiftUI

struct ContentView: View {
    @StateObject private var model = FrameHandler()
    
    var body: some View {
        GameView(frameHandler: model)
            .ignoresSafeArea()
    }
}
