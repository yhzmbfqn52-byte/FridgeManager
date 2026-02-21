//
//  FridgeManagerApp.swift
//  FridgeManager
//
//  Created by Filip Herman on 19/02/2026.
//

import SwiftUI
import SwiftData

@main
struct FridgeManagerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FridgeItem.self,
            Fridge.self,
            Shelf.self,
            Drawer.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var isShowingSplash: Bool = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .opacity(isShowingSplash ? 0 : 1)

                if isShowingSplash {
                    SplashView()
                        .transition(.opacity)
                        .onAppear {
                            // Keep the splash visible for 3 seconds then fade out
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeOut(duration: 0.6)) {
                                    isShowingSplash = false
                                }
                            }
                        }
                }
            }
            .modelContainer(sharedModelContainer)
            .preferredColorScheme(.dark)
            .accentColor(Color(.systemTeal))
        }
    }
}
