import Foundation
import Combine

@MainActor
final class BirdCargoViewModel: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let businessLogic: BirdCargoBusinessLogic
    private var timeoutTask: Task<Void, Never>?
    
    init(businessLogic: BirdCargoBusinessLogic) {
        self.businessLogic = businessLogic
    }
    
    func initialize() {
        Task {
            _ = await businessLogic.initialize()
            scheduleTimeout()
        }
    }
    
    func handleTracking(_ data: [String: Any]) {
        Task {
            _ = businessLogic.handleTracking(data)
            
            await performValidation()
        }
    }
    
    func handleNavigation(_ data: [String: Any]) {
        Task {
            businessLogic.handleNavigation(data)
        }
    }
    
    func requestPermission() {
        Task {
            _ = await businessLogic.requestPermission()
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func deferPermission() {
        Task {
            businessLogic.deferPermission()
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func networkStatusChanged(_ isConnected: Bool) {
        Task {
            showOfflineView = !isConnected
        }
    }
    
    func timeout() {
        Task {
            if !isP {
                timeoutTask?.cancel()
                navigateToMain = true
            }
        }
    }
    
    // MARK: - Private Logic
    
    private func performValidation() async {
        if !isP {
            do {
                let isValid = try await businessLogic.validate()
                isP = true
                if isValid {
                    // ✅ Validation passed
                    await executeBusinessLogic()
                } else {
                    // ❌ Validation failed - сразу на Main!
                    timeoutTask?.cancel()
                    navigateToMain = true
                }
            } catch {
                print("🐦 [BirdCargo] Validation error: \(error)")
                timeoutTask?.cancel()
                navigateToMain = true
            }
        }
    }
    
    private var isP = false
    
    private func executeBusinessLogic() async {
        do {
            let url = try await businessLogic.executeBusinessLogic()
            businessLogic.finalizeWithEndpoint(url)
            
            if businessLogic.canAskPermission() {
                showPermissionPrompt = true
            } else {
                navigateToWeb = true
            }
        } catch {
            print("🐦 [BirdCargo] Business logic error: \(error)")
            navigateToMain = true
        }
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await timeout()
        }
    }
}
