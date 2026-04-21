import SwiftUI

@main
struct BirdCargoFarmApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }

}

// MARK: - Root View
struct RootView: View {
    @StateObject private var store = AppStore()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else if store.isAuthenticated {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                WelcomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSplash)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.isAuthenticated)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: hasCompletedOnboarding)
        .environmentObject(store)
        .preferredColorScheme(colorScheme(for: store.themeMode))
    }
    
    private func colorScheme(for mode: String) -> ColorScheme? {
        switch mode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
    
}
