import SwiftUI

struct AppLogoView: View {
    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height)
            let corner = w * 0.12

            ZStack {
                // Fridge body
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [Color(white: 0.15), Color(white: 0.08)]), startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: corner)
                            .stroke(Color.white.opacity(0.08), lineWidth: max(1, w * 0.02))
                    )

                VStack(spacing: w * 0.06) {
                    // Upper freezer compartment
                    RoundedRectangle(cornerRadius: corner * 0.7)
                        .fill(Color(white: 0.06))
                        .frame(height: w * 0.36)
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.02))
                                .frame(height: 1)
                                .offset(y: w * 0.18), alignment: .top
                        )

                    // Lower fridge door
                    RoundedRectangle(cornerRadius: corner * 0.7)
                        .fill(Color(white: 0.02))
                        .frame(height: w * 0.36)
                }
                .padding(w * 0.08)

                // Handle
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: w * 0.02)
                            .fill(
                                LinearGradient(gradient: Gradient(colors: [Color(.systemGray2), Color(.systemGray4)]), startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: w * 0.12, height: w * 0.04)
                            .offset(x: -w * 0.08, y: -w * 0.12)
                    }
                }

                // Small sparkle to add polish
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: w * 0.06, height: w * 0.06)
                    .offset(x: -w * 0.22, y: -w * 0.28)
                    .blur(radius: 0.5)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct AppLogoView_Previews: PreviewProvider {
    static var previews: some View {
        AppLogoView()
            .frame(width: 120, height: 120)
            .padding()
            .background(Color.black)
    }
}
