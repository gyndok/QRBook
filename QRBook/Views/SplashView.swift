import SwiftUI

struct SplashView: View {
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.electricViolet.opacity(0.18),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Text("QR Snap Vault")
                    .font(.screenTitle)
                    .foregroundStyle(Color.electricViolet)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOpacity = 1
            }
        }
    }
}
