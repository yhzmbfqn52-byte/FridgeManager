import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoRotation: Double = -12
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        // Check for a custom asset named "AppLogo" and fall back to the SF Symbol
        let hasCustomLogo = UIImage(named: "AppLogo") != nil

        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(.systemBlue), Color(.systemTeal)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Group {
                    if hasCustomLogo {
                        Image("AppLogo")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .accessibilityLabel("FridgeManager logo")
                    } else {
                        AppLogoView()
                            .accessibilityLabel("FridgeManager logo")
                    }
                }
                .frame(width: 80, height: 80)
                .scaleEffect(logoScale)
                .rotationEffect(.degrees(logoRotation))
                .opacity(logoOpacity)
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)

                Text("FridgeManager by Filip Herman")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                    .scaleEffect(textOpacity > 0 ? 1 : 0.98)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 12)
        }
        .onAppear {
            // Step 1: pop in the logo
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                logoScale = 1.05
                logoRotation = 8
                logoOpacity = 1
            }

            // Step 2: settle back to final state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.35)) {
                    logoScale = 1.0
                    logoRotation = 0
                }
            }

            // Step 3: reveal the text slightly after the logo pops
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeIn(duration: 0.45)) {
                    textOpacity = 1
                }
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .previewLayout(.device)
    }
}
