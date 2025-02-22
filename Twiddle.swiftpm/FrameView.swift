import SwiftUI

struct FrameView: View {
    var image: CGImage?
    private let label = Text("frame")
    @ObservedObject var frameHandler: FrameHandler
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = frameHandler.frame {
                    Image(image, scale: 1.0, orientation: .up, label: label)
                        .resizable()
                        .scaledToFit()
                        //.frame(width: geometry.size.width, height: geometry.size.height)
                        
                } else {
                    Color.black
                }
                
                // 손가락 끝에 원 그리기 함수 호출
                drawFingerPoints(in: geometry,fingers: frameHandler.fingerPoints, color: Color.orange)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    @ViewBuilder
    public func drawFingerPoints(in geometry: GeometryProxy, fingers: [CGPoint], color: Color) -> some View {
        let displayColor = fingers.isEmpty ? Color.clear : color
        
        ForEach(fingers, id: \.self) { point in
            Circle()
                .fill(displayColor)
                .frame(width: 10, height: 10)
                .position(x: point.x * geometry.size.width, y: point.y * geometry.size.height)
        }
    }
}
