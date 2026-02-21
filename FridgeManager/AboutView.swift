import SwiftUI

struct AboutView: View {
    var onDone: (() -> Void)?

    @Environment(\.openURL) private var openURL

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "FridgeManager"
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(v) (Build \(b))"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(appName)
                .font(.title)
                .fontWeight(.bold)

            Text(appVersion)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("FridgeManager helps you model and manage your fridge inventory and shelves.")
                .multilineTextAlignment(.center)
                .padding()

            // Link button to open the Razor website
            Button {
                if let url = URL(string: "https://www.razor.be") {
                    openURL(url)
                }
            } label: {
                Label("Visit razor.be", systemImage: "link")
                    .font(.body)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding()
        .navigationTitle("About")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { onDone?() }
            }
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AboutView()
        }
        .preferredColorScheme(.dark)
    }
}
