import SwiftUI

struct AnimatedNumberView: View {
    let targetValue: Int
    let duration: Double
    var font: Font = .system(size: 28, weight: .black)
    var color: Color = .white

    @State private var displayValue: Int = 0

    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundColor(color)
            .onAppear {
                animateTo(targetValue)
            }
            .onChange(of: targetValue) { newValue in
                animateTo(newValue)
            }
    }

    private func animateTo(_ target: Int) {
        let steps = 60
        let stepDuration = duration / Double(steps)
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Double(i) / Double(steps)
                displayValue = Int(Double(target) * progress)
            }
        }
    }
}
