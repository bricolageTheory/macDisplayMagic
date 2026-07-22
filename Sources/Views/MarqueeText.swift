import SwiftUI

/// Auto-scrolling marquee text component that slowly scrolls horizontally when text overflows available width.
public struct MarqueeText: View {
    public let text: String
    public let font: Font
    public var speed: Double = 25.0 // Points per second

    @State private var animate = false
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    public init(text: String, font: Font = .headline, speed: Double = 25.0) {
        self.text = text
        self.font = font
        self.speed = speed
    }

    public var body: some View {
        GeometryReader { containerGeo in
            let cWidth = containerGeo.size.width

            HStack(spacing: 0) {
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        GeometryReader { textGeo in
                            Color.clear
                                .onAppear {
                                    textWidth = textGeo.size.width
                                    containerWidth = cWidth
                                    checkAndStartAnimation(textW: textGeo.size.width, containerW: cWidth)
                                }
                                .onChange(of: textGeo.size.width) { newWidth in
                                    textWidth = newWidth
                                    checkAndStartAnimation(textW: newWidth, containerW: containerWidth)
                                }
                        }
                    )
                    .offset(x: animate && textWidth > containerWidth ? -(textWidth - containerWidth) : 0)
                
                Spacer(minLength: 0)
            }
        }
        .frame(height: 20)
        .clipped()
    }

    private func checkAndStartAnimation(textW: CGFloat, containerW: CGFloat) {
        guard textW > containerW && containerW > 0 else {
            animate = false
            return
        }
        let overflow = textW - containerW
        let duration = Double(overflow) / speed + 1.0

        withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(1.5)) {
            animate = true
        }
    }
}
