import Foundation
import Combine
import UserNotifications

class AppStore: ObservableObject {
    static let shared = AppStore()

    // MARK: - Auth
    @Published var currentUser: BCUser?
    @Published var isAuthenticated: Bool = false

    // MARK: - Data
    @Published var transportPlans: [TransportPlan] = []
    @Published var vehicles: [Vehicle] = []
    @Published var birdGroups: [BirdGroup] = []
    @Published var containers: [BirdContainer] = []
    @Published var routeStops: [RouteStop] = []
    @Published var conditionLogs: [ConditionLog] = []
    @Published var housings: [Housing] = []
    @Published var healthRecords: [HealthRecord] = []
    @Published var supplies: [Supply] = []
    @Published var tasks: [TransportTask] = []
    @Published var activities: [ActivityRecord] = []
    @Published var loadingAssignments: [LoadingAssignment] = []

    // MARK: - Settings
    @Published var themeMode: String {
        didSet { UserDefaults.standard.set(themeMode, forKey: "themeMode") }
    }
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            handleNotificationToggle()
        }
    }
    @Published var temperatureUnit: String {
        didSet { UserDefaults.standard.set(temperatureUnit, forKey: "temperatureUnit") }
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        self.themeMode = UserDefaults.standard.string(forKey: "themeMode") ?? "system"
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.temperatureUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "Celsius"

        loadAllData()
        checkAuthState()
    }

    // MARK: - Persistence
    private func save<T: Codable>(_ items: [T], key: String) {
        if let data = try? encoder.encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load<T: Codable>(_ type: [T].Type, key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? decoder.decode([T].self, from: data) else { return [] }
        return items
    }

    func loadAllData() {
        transportPlans = load([TransportPlan].self, key: "transportPlans")
        vehicles       = load([Vehicle].self, key: "vehicles")
        birdGroups     = load([BirdGroup].self, key: "birdGroups")
        containers     = load([BirdContainer].self, key: "containers")
        routeStops     = load([RouteStop].self, key: "routeStops")
        conditionLogs  = load([ConditionLog].self, key: "conditionLogs")
        housings       = load([Housing].self, key: "housings")
        healthRecords  = load([HealthRecord].self, key: "healthRecords")
        supplies       = load([Supply].self, key: "supplies")
        tasks          = load([TransportTask].self, key: "tasks")
        activities     = load([ActivityRecord].self, key: "activities")
        loadingAssignments = load([LoadingAssignment].self, key: "loadingAssignments")

        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? decoder.decode(BCUser.self, from: userData) {
            currentUser = user
        }
    }

    private func saveUser() {
        if let user = currentUser, let data = try? encoder.encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUser")
        }
    }

    func saveAllData() {
        save(transportPlans, key: "transportPlans")
        save(vehicles,       key: "vehicles")
        save(birdGroups,     key: "birdGroups")
        save(containers,     key: "containers")
        save(routeStops,     key: "routeStops")
        save(conditionLogs,  key: "conditionLogs")
        save(housings,       key: "housings")
        save(healthRecords,  key: "healthRecords")
        save(supplies,       key: "supplies")
        save(tasks,          key: "tasks")
        save(activities,     key: "activities")
        save(loadingAssignments, key: "loadingAssignments")
        saveUser()
    }

    // MARK: - Auth
    private func checkAuthState() {
        isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
    }

    func login(email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        // Load registered users
        if let data = UserDefaults.standard.data(forKey: "registeredUsers"),
           let users = try? decoder.decode([BCUser].self, from: data) {
            // Also check stored passwords
            if let passData = UserDefaults.standard.data(forKey: "userPasswords"),
               let passwords = try? decoder.decode([String: String].self, from: passData),
               let user = users.first(where: { $0.email.lowercased() == email.lowercased() }),
               passwords[user.id] == password {
                currentUser = user
                isAuthenticated = true
                UserDefaults.standard.set(true, forKey: "isAuthenticated")
                saveUser()
                completion(true, "")
                return
            }
        }
        completion(false, "Invalid email or password.")
    }

    func loginDemo() {
        let demo = BCUser(id: "demo", name: "Demo Farmer", email: "demo@birdcargo.com", farm: "Bird Cargo Demo Farm")
        currentUser = demo
        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        saveUser()
        if transportPlans.isEmpty { seedDemoData() }
    }

    func register(name: String, email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        // Check existing
        if let data = UserDefaults.standard.data(forKey: "registeredUsers"),
           let users = try? decoder.decode([BCUser].self, from: data),
           users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            completion(false, "Email already registered.")
            return
        }
        let user = BCUser(name: name, email: email, farm: "\(name)'s Farm")
        var users: [BCUser] = []
        if let data = UserDefaults.standard.data(forKey: "registeredUsers"),
           let existing = try? decoder.decode([BCUser].self, from: data) {
            users = existing
        }
        users.append(user)
        if let data = try? encoder.encode(users) {
            UserDefaults.standard.set(data, forKey: "registeredUsers")
        }
        // Store password
        var passwords: [String: String] = [:]
        if let data = UserDefaults.standard.data(forKey: "userPasswords"),
           let existing = try? decoder.decode([String: String].self, from: data) {
            passwords = existing
        }
        passwords[user.id] = password
        if let data = try? encoder.encode(passwords) {
            UserDefaults.standard.set(data, forKey: "userPasswords")
        }
        currentUser = user
        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        saveUser()
        completion(true, "")
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }

    func deleteAccount() {
        // Remove from registered users
        if let user = currentUser,
           let data = UserDefaults.standard.data(forKey: "registeredUsers"),
           var users = try? decoder.decode([BCUser].self, from: data) {
            users.removeAll { $0.id == user.id }
            if let newData = try? encoder.encode(users) {
                UserDefaults.standard.set(newData, forKey: "registeredUsers")
            }
        }
        logout()
        // Clear all user data
        let keys = ["transportPlans","vehicles","birdGroups","containers","routeStops",
                    "conditionLogs","housings","healthRecords","supplies","tasks","activities","loadingAssignments"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        transportPlans = []; vehicles = []; birdGroups = []; containers = []
        routeStops = []; conditionLogs = []; housings = []; healthRecords = []
        supplies = []; tasks = []; activities = []; loadingAssignments = []
    }

    func updateProfile(name: String, farm: String) {
        currentUser?.name = name
        currentUser?.farm = farm
        saveUser()
        logActivity("Updated profile", icon: "person.fill", category: "Profile")
    }

    // MARK: - Transport Plans
    func addTransportPlan(_ plan: TransportPlan) {
        transportPlans.insert(plan, at: 0)
        save(transportPlans, key: "transportPlans")
        logActivity("Created transport: \(plan.name)", icon: "truck.box.fill", category: "Transport")
    }

    func updateTransportPlan(_ plan: TransportPlan) {
        if let i = transportPlans.firstIndex(where: { $0.id == plan.id }) {
            transportPlans[i] = plan
            save(transportPlans, key: "transportPlans")
        }
    }

    func deleteTransportPlan(_ id: String) {
        transportPlans.removeAll { $0.id == id }
        save(transportPlans, key: "transportPlans")
        logActivity("Deleted transport plan", icon: "trash.fill", category: "Transport")
    }

    // MARK: - Vehicles
    func addVehicle(_ v: Vehicle) {
        vehicles.insert(v, at: 0)
        save(vehicles, key: "vehicles")
        logActivity("Added vehicle: \(v.name)", icon: "truck.box.fill", category: "Vehicle")
    }

    func updateVehicle(_ v: Vehicle) {
        if let i = vehicles.firstIndex(where: { $0.id == v.id }) {
            vehicles[i] = v
            save(vehicles, key: "vehicles")
        }
    }

    func deleteVehicle(_ id: String) {
        vehicles.removeAll { $0.id == id }
        save(vehicles, key: "vehicles")
    }

    // MARK: - Bird Groups
    func addBirdGroup(_ g: BirdGroup) {
        birdGroups.insert(g, at: 0)
        save(birdGroups, key: "birdGroups")
        logActivity("Added bird group: \(g.name) (\(g.type.rawValue))", icon: "bird.fill", category: "Birds")
    }

    func updateBirdGroup(_ g: BirdGroup) {
        if let i = birdGroups.firstIndex(where: { $0.id == g.id }) {
            birdGroups[i] = g
            save(birdGroups, key: "birdGroups")
        }
    }

    func deleteBirdGroup(_ id: String) {
        birdGroups.removeAll { $0.id == id }
        save(birdGroups, key: "birdGroups")
    }

    // MARK: - Containers
    func addContainer(_ c: BirdContainer) {
        containers.insert(c, at: 0)
        save(containers, key: "containers")
        logActivity("Added container: \(c.name)", icon: "shippingbox.fill", category: "Container")
    }

    func updateContainer(_ c: BirdContainer) {
        if let i = containers.firstIndex(where: { $0.id == c.id }) {
            containers[i] = c
            save(containers, key: "containers")
        }
    }

    func deleteContainer(_ id: String) {
        containers.removeAll { $0.id == id }
        save(containers, key: "containers")
    }

    // MARK: - Route Stops
    func addRouteStop(_ s: RouteStop) {
        routeStops.append(s)
        save(routeStops, key: "routeStops")
        logActivity("Added route stop: \(s.name)", icon: "mappin.fill", category: "Route")
    }

    func updateRouteStop(_ s: RouteStop) {
        if let i = routeStops.firstIndex(where: { $0.id == s.id }) {
            routeStops[i] = s
            save(routeStops, key: "routeStops")
        }
    }

    func deleteRouteStop(_ id: String) {
        routeStops.removeAll { $0.id == id }
        save(routeStops, key: "routeStops")
    }

    func stopsFor(_ planId: String) -> [RouteStop] {
        routeStops.filter { $0.transportPlanId == planId }.sorted { $0.estimatedTime < $1.estimatedTime }
    }

    // MARK: - Condition Logs
    func addConditionLog(_ log: ConditionLog) {
        conditionLogs.insert(log, at: 0)
        save(conditionLogs, key: "conditionLogs")
        logActivity("Logged conditions: \(String(format: "%.1f", log.temperature))°", icon: "thermometer.medium", category: "Conditions")
    }

    func logsFor(_ planId: String) -> [ConditionLog] {
        conditionLogs.filter { $0.transportPlanId == planId }.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Housings
    func addHousing(_ h: Housing) {
        housings.insert(h, at: 0)
        save(housings, key: "housings")
        logActivity("Added housing: \(h.name)", icon: "house.fill", category: "Housing")
    }

    func updateHousing(_ h: Housing) {
        if let i = housings.firstIndex(where: { $0.id == h.id }) {
            housings[i] = h
            save(housings, key: "housings")
        }
    }

    func deleteHousing(_ id: String) {
        housings.removeAll { $0.id == id }
        save(housings, key: "housings")
    }

    // MARK: - Health Records
    func addHealthRecord(_ r: HealthRecord) {
        healthRecords.insert(r, at: 0)
        save(healthRecords, key: "healthRecords")
        logActivity("Health check recorded", icon: "cross.case.fill", category: "Health")
    }

    func recordsFor(_ groupId: String) -> [HealthRecord] {
        healthRecords.filter { $0.birdGroupId == groupId }.sorted { $0.date > $1.date }
    }

    // MARK: - Supplies
    func addSupply(_ s: Supply) {
        supplies.insert(s, at: 0)
        save(supplies, key: "supplies")
        logActivity("Added supply: \(s.name)", icon: "bag.fill", category: "Supplies")
    }

    func updateSupply(_ s: Supply) {
        if let i = supplies.firstIndex(where: { $0.id == s.id }) {
            supplies[i] = s
            save(supplies, key: "supplies")
        }
    }

    func deleteSupply(_ id: String) {
        supplies.removeAll { $0.id == id }
        save(supplies, key: "supplies")
    }

    // MARK: - Tasks
    func addTask(_ t: TransportTask) {
        tasks.insert(t, at: 0)
        save(tasks, key: "tasks")
        logActivity("Added task: \(t.title)", icon: "checklist", category: "Tasks")
        if notificationsEnabled {
            scheduleTaskNotification(t)
        }
    }

    func toggleTask(_ id: String) {
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].completed.toggle()
            save(tasks, key: "tasks")
        }
    }

    func deleteTask(_ id: String) {
        tasks.removeAll { $0.id == id }
        save(tasks, key: "tasks")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Loading Assignments
    func addLoadingAssignment(_ a: LoadingAssignment) {
        loadingAssignments.append(a)
        // Update container load
        if let i = containers.firstIndex(where: { $0.id == a.containerId }) {
            containers[i].currentLoad += a.birdCount
            let cap = containers[i].capacity
            let load = containers[i].currentLoad
            containers[i].status = load >= cap ? .full : (load > 0 ? .partial : .empty)
            save(containers, key: "containers")
        }
        save(loadingAssignments, key: "loadingAssignments")
        logActivity("Loaded \(a.birdCount) birds into container", icon: "arrow.down.to.line.compact", category: "Loading")
    }

    func assignmentsFor(_ planId: String) -> [LoadingAssignment] {
        loadingAssignments.filter { $0.transportPlanId == planId }
    }

    // MARK: - Activity
    func logActivity(_ action: String, icon: String, category: String) {
        let record = ActivityRecord(timestamp: Date(), action: action, icon: icon, category: category)
        activities.insert(record, at: 0)
        if activities.count > 200 { activities = Array(activities.prefix(200)) }
        save(activities, key: "activities")
    }

    // MARK: - Notifications
    func handleNotificationToggle() {
        if notificationsEnabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    if !granted { self.notificationsEnabled = false }
                }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    private func scheduleTaskNotification(_ task: TransportTask) {
        guard task.dueDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Bird Cargo Farm"
        content.body = "Task due: \(task.title)"
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: task.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - Dashboard Stats
    var activePlans: [TransportPlan] {
        transportPlans.filter { $0.status == .inProgress }
    }

    var totalBirdsInTransit: Int {
        let planIds = activePlans.map { $0.id }
        return birdGroups.filter { g in planIds.contains(g.transportPlanId ?? "") }.reduce(0) { $0 + $1.count }
    }

    var containersInUse: Int {
        containers.filter { $0.currentLoad > 0 }.count
    }

    var upcomingPlans: [TransportPlan] {
        transportPlans.filter { $0.status == .planned && $0.date > Date() }
            .sorted { $0.date < $1.date }
    }

    var pendingTasks: [TransportTask] {
        tasks.filter { !$0.completed }.sorted { $0.dueDate < $1.dueDate }
    }

    // MARK: - Reports
    var transportCount: Int { transportPlans.count }
    var completedTransports: Int { transportPlans.filter { $0.status == .completed }.count }
    var totalBirdsTransported: Int { transportPlans.reduce(0) { $0 + $1.birdCount } }
    var healthyBirdPercent: Double {
        guard !birdGroups.isEmpty else { return 0 }
        let healthy = birdGroups.filter { $0.healthStatus == .healthy }.count
        return Double(healthy) / Double(birdGroups.count) * 100
    }

    // MARK: - Demo Seed Data
    func seedDemoData() {
        let vid = UUID().uuidString
        let v = Vehicle(id: vid, name: "Farm Truck #1", type: .truck, plateNumber: "AGR-1234", capacity: 500, notes: "Main transport vehicle")
        addVehicle(v)

        let g1id = UUID().uuidString
        let g1 = BirdGroup(id: g1id, name: "Batch A Chickens", type: .chicken, count: 150, age: 12, weightKg: 1.8, notes: "", healthStatus: .healthy, transportPlanId: nil)
        addBirdGroup(g1)
        let g2 = BirdGroup(id: UUID().uuidString, name: "Ducks Group 1", type: .duck, count: 60, age: 8, weightKg: 2.1, notes: "", healthStatus: .healthy, transportPlanId: nil)
        addBirdGroup(g2)

        let c1 = BirdContainer(id: UUID().uuidString, name: "Cage-01", capacity: 30, currentLoad: 0, type: .cage, status: .empty, birdGroupId: nil)
        addContainer(c1)
        let c2 = BirdContainer(id: UUID().uuidString, name: "Cage-02", capacity: 30, currentLoad: 0, type: .cage, status: .empty, birdGroupId: nil)
        addContainer(c2)
        let c3 = BirdContainer(id: UUID().uuidString, name: "Crate-01", capacity: 50, currentLoad: 0, type: .crate, status: .empty, birdGroupId: nil)
        addContainer(c3)

        var plan = TransportPlan(name: "Spring Delivery Run", date: Date().addingTimeInterval(86400 * 3), origin: "Main Farm", destination: "City Market", birdCount: 150, status: .planned, vehicleId: vid, notes: "Regular spring market delivery")
        addTransportPlan(plan)

        var plan2 = TransportPlan(name: "Duck Transfer", date: Date().addingTimeInterval(-86400), origin: "Pond Farm", destination: "North Facility", birdCount: 60, status: .inProgress, vehicleId: vid, notes: "")
        addTransportPlan(plan2)

        addHousing(Housing(name: "Main Coop A", capacity: 200, currentOccupancy: 150, type: .coop, notes: "Primary chicken housing"))
        addHousing(Housing(name: "Duck Pond House", capacity: 80, currentOccupancy: 60, type: .pen, notes: "Waterfront housing"))

        let t1 = TransportTask(title: "Prepare containers", dueDate: Date().addingTimeInterval(3600), completed: false, priority: .high, transportPlanId: plan.id, notes: "")
        addTask(t1)
        let t2 = TransportTask(title: "Load birds", dueDate: Date().addingTimeInterval(7200), completed: false, priority: .high, transportPlanId: plan.id, notes: "")
        addTask(t2)
        let t3 = TransportTask(title: "Check vehicle fuel", dueDate: Date().addingTimeInterval(1800), completed: true, priority: .medium, transportPlanId: plan.id, notes: "")
        addTask(t3)

        addSupply(Supply(name: "Poultry Feed", type: .feed, quantity: 50, unit: "kg"))
        addSupply(Supply(name: "Water", type: .water, quantity: 100, unit: "L"))
    }
}
