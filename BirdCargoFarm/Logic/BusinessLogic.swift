import Foundation
import AppsFlyerLib

final class BirdCargoBusinessLogic {
    private let storage: StorageService
    private let validation: ValidationService
    private let network: NetworkService
    private let notification: NotificationService
    
    private var model: AppModel = .initial
    
    init(
        storage: StorageService,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        self.storage = storage
        self.validation = validation
        self.network = network
        self.notification = notification
    }
    
    // MARK: - Initialize
    
    func initialize() async -> AppModel {
        let stored = storage.loadState()
        model.tracking = stored.tracking
        model.navigation = stored.navigation
        model.mode = stored.mode
        model.isFirstLaunch = stored.isFirstLaunch
        model.permission = AppModel.PermissionModel(
            isGranted: stored.permission.isGranted,
            isDenied: stored.permission.isDenied,
            lastAsked: stored.permission.lastAsked
        )
        
        return model
    }
    
    // MARK: - Handle Tracking
    
    func handleTracking(_ data: [String: Any]) -> AppModel {
        let converted = data.mapValues { "\($0)" }
        model.tracking = converted
        storage.saveTracking(converted)
        return model
    }
    
    func handleNavigation(_ data: [String: Any]) {
        let converted = data.mapValues { "\($0)" }
        model.navigation = converted
        storage.saveNavigation(converted)
    }
    
    // MARK: - Validation
    
    func validate() async throws -> Bool {
        guard model.hasTracking() else {
            return false
        }
        
        do {
            return try await validation.validate()
        } catch {
            print("🐦 [BirdCargo] Validation error: \(error)")
            throw error
        }
    }
    
    // MARK: - Business Logic
    
    func executeBusinessLogic() async throws -> String {
        guard !model.isLocked, model.hasTracking() else {
            throw AppError.notFound
        }
        
        // Check temp_url
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            return temp
        }
        
        // Check organic + first launch
        let attributionProcessed = model.metadata["attribution_processed"] == "true"
        if model.isOrganic() && model.isFirstLaunch && !attributionProcessed {
            model.metadata["attribution_processed"] = "true"
            try await executeOrganicFlow()
        }
        
        // Fetch endpoint
        return try await fetchEndpoint()
    }
    
    private func executeOrganicFlow() async throws {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !model.isLocked else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        var fetched = try await network.fetchAttribution(deviceID: deviceID)
        
        for (key, value) in model.navigation {
            if fetched[key] == nil {
                fetched[key] = value
            }
        }
        
        let converted = fetched.mapValues { "\($0)" }
        model.tracking = converted
        storage.saveTracking(converted)
    }
    
    private func fetchEndpoint() async throws -> String {
        guard !model.isLocked else {
            throw AppError.notFound
        }
        
        let trackingDict = model.tracking.mapValues { $0 as Any }
        return try await network.fetchEndpoint(tracking: trackingDict)
    }
    
    func finalizeWithEndpoint(_ url: String) {
        model.endpoint = url
        model.mode = "Active"
        model.isFirstLaunch = false
        model.isLocked = true
        
        storage.saveEndpoint(url)
        storage.saveMode("Active")
        storage.markLaunched()
    }
    
    // MARK: - Permission
    
    func requestPermission() async -> AppModel.PermissionModel {
        // ✅ Локальная копия для избежания inout capture
        var localPermission = model.permission
        
        let updatedPermission = await withCheckedContinuation {
            (continuation: CheckedContinuation<AppModel.PermissionModel, Never>) in
            
            notification.requestPermission { granted in
                var permission = localPermission
                
                if granted {
                    permission.isGranted = true
                    permission.isDenied = false
                    permission.lastAsked = Date()
                    self.notification.registerForPush()
                } else {
                    permission.isGranted = false
                    permission.isDenied = true
                    permission.lastAsked = Date()
                }
                
                continuation.resume(returning: permission)
            }
        }
        
        model.permission = updatedPermission
        storage.savePermissions(updatedPermission)
        return updatedPermission
    }
    
    func deferPermission() {
        model.permission.lastAsked = Date()
        storage.savePermissions(model.permission)
    }
    
    func canAskPermission() -> Bool {
        model.permission.canAsk
    }
}
