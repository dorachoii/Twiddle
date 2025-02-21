import SwiftUI

struct FrameView: View {
    var image: CGImage?
    private let label = Text("frame")
    
    var body: some View {
        if let image = image {
            // camera Image를 받을 곳
            Image(image, scale: 1.0, orientation: .up, label: label)
        } else {
            Color.black
        }
    }
}
