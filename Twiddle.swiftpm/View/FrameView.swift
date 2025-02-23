import SwiftUI

struct FrameView: View {
    var image: CGImage?
    private let label = Text("frame")
    
    @ObservedObject var frameHandler: FrameHandler
    
    var body: some View {
        ZStack {
            if let image = frameHandler.frame {
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            } else {
                Color.black
            }
        }
    }
}

