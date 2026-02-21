import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showWizard: Bool = false
    @State private var didAppear: Bool = false

    public init() {}

    var body: some View {
        ContentView()
            .onAppear {
                guard !didAppear else { return }
                didAppear = true

                // Show the wizard only on the very first launch (or if the flag was reset)
                let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedWizard")
                if !hasCompleted {
                    // Delay to allow splash to finish if present
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        showWizard = true
                    }
                }
            }
            .sheet(isPresented: $showWizard) {
                FridgeWizardView(onComplete: { showWizard = false })
            }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .modelContainer(for: [Fridge.self, Shelf.self, Drawer.self], inMemory: true)
            .preferredColorScheme(.dark)
    }
}
