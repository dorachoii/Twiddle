import SwiftUI

struct GameStepView: View {
    @ObservedObject var frameHandler: FrameHandler
    var geometry: GeometryProxy
    let step: Int
    
    var body: some View{
        ZStack{
            drawFingerPoints(fingers: frameHandler.fingerPoints, color: Color.orange)
            
            VStack {
                Spacer()
                HStack(spacing: 30) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index < frameHandler.completedFistCount ? Color.green : Color.gray)
                            .frame(width: 30, height: 30)
                    }
                }
                .padding(.bottom, 20) // 원들이 너무 아래 붙지 않도록 패딩 추가
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
}
