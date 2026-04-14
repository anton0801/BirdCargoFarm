import Foundation

// MARK: - User
struct BCUser: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var email: String
    var farm: String
    var createdAt: Date = Date()
}

// MARK: - Transport Plan
struct TransportPlan: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var date: Date
    var origin: String
    var destination: String
    var birdCount: Int
    var status: TransportStatus
    var vehicleId: String?
    var notes: String
    var createdAt: Date = Date()

    enum TransportStatus: String, Codable, CaseIterable {
        case planned = "Planned"
        case inProgress = "In Progress"
        case arrived = "Arrived"
        case completed = "Completed"

        var color: String {
            switch self {
            case .planned: return "#F4A261"
            case .inProgress: return "#52B788"
            case .arrived: return "#2D6A4F"
            case .completed: return "#9BB8A0"
            }
        }
    }
}

// MARK: - Vehicle
struct Vehicle: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var type: VehicleType
    var plateNumber: String
    var capacity: Int
    var notes: String

    enum VehicleType: String, Codable, CaseIterable {
        case truck = "Truck"
        case van = "Van"
        case trailer = "Trailer"
        case pickup = "Pickup"
    }
}

// MARK: - Bird Group
struct BirdGroup: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var type: BirdType
    var count: Int
    var age: Int // weeks
    var weightKg: Double
    var notes: String
    var healthStatus: HealthStatus
    var transportPlanId: String?

    enum BirdType: String, Codable, CaseIterable {
        case chicken = "Chicken"
        case duck = "Duck"
        case goose = "Goose"
        case quail = "Quail"
        case turkey = "Turkey"

        var icon: String {
            switch self {
            case .chicken: return "🐔"
            case .duck: return "🦆"
            case .goose: return "🪿"
            case .quail: return "🐦"
            case .turkey: return "🦃"
            }
        }
    }

    enum HealthStatus: String, Codable, CaseIterable {
        case healthy = "Healthy"
        case monitor = "Monitor"
        case sick = "Sick"
    }
}

// MARK: - Container
struct BirdContainer: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var capacity: Int
    var currentLoad: Int
    var type: ContainerType
    var status: ContainerStatus
    var birdGroupId: String?

    var availableSpace: Int { capacity - currentLoad }
    var isFull: Bool { currentLoad >= capacity }
    var occupancyPercent: Double { capacity > 0 ? Double(currentLoad) / Double(capacity) : 0 }

    enum ContainerType: String, Codable, CaseIterable {
        case cage = "Cage"
        case crate = "Crate"
        case box = "Box"
    }

    enum ContainerStatus: String, Codable, CaseIterable {
        case empty = "Empty"
        case partial = "Partial"
        case full = "Full"
        case inTransit = "In Transit"
    }
}

// MARK: - Route Stop
struct RouteStop: Codable, Identifiable {
    var id: String = UUID().uuidString
    var transportPlanId: String
    var name: String
    var type: StopType
    var estimatedTime: Date
    var notes: String
    var completed: Bool = false

    enum StopType: String, Codable, CaseIterable {
        case departure = "Departure"
        case rest = "Rest Stop"
        case feed = "Feed Stop"
        case vet = "Vet Check"
        case arrival = "Arrival"

        var icon: String {
            switch self {
            case .departure: return "arrow.up.circle.fill"
            case .rest: return "zzz"
            case .feed: return "fork.knife"
            case .vet: return "cross.case.fill"
            case .arrival: return "checkmark.circle.fill"
            }
        }
    }
}

// MARK: - Condition Log
struct ConditionLog: Codable, Identifiable {
    var id: String = UUID().uuidString
    var transportPlanId: String
    var timestamp: Date
    var temperature: Double  // Celsius
    var humidity: Double     // %
    var ventilation: VentilationLevel
    var notes: String

    enum VentilationLevel: String, Codable, CaseIterable {
        case poor = "Poor"
        case fair = "Fair"
        case good = "Good"
        case excellent = "Excellent"
    }
}

// MARK: - Housing
struct Housing: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var capacity: Int
    var currentOccupancy: Int
    var type: HousingType
    var notes: String

    var availableSpace: Int { capacity - currentOccupancy }

    enum HousingType: String, Codable, CaseIterable {
        case coop = "Coop"
        case barn = "Barn"
        case pen = "Pen"
        case cage = "Cage"
    }
}

// MARK: - Health Record
struct HealthRecord: Codable, Identifiable {
    var id: String = UUID().uuidString
    var birdGroupId: String
    var date: Date
    var condition: String
    var notes: String
    var checkType: CheckType

    enum CheckType: String, Codable, CaseIterable {
        case preDeparture = "Pre-Departure"
        case enRoute = "En Route"
        case arrival = "Arrival"
        case postArrival = "Post-Arrival"
    }
}

// MARK: - Supply
struct Supply: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var type: SupplyType
    var quantity: Double
    var unit: String
    var transportPlanId: String?

    enum SupplyType: String, Codable, CaseIterable {
        case feed = "Feed"
        case water = "Water"
        case medicine = "Medicine"
        case equipment = "Equipment"
    }
}

// MARK: - Task
struct TransportTask: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var dueDate: Date
    var completed: Bool = false
    var priority: Priority
    var transportPlanId: String?
    var notes: String

    enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: String {
            switch self {
            case .low: return "#9BB8A0"
            case .medium: return "#F4A261"
            case .high: return "#E76F51"
            }
        }
    }
}

// MARK: - Activity
struct ActivityRecord: Codable, Identifiable {
    var id: String = UUID().uuidString
    var timestamp: Date
    var action: String
    var icon: String
    var category: String
}

// MARK: - Loading Assignment
struct LoadingAssignment: Codable, Identifiable {
    var id: String = UUID().uuidString
    var transportPlanId: String
    var birdGroupId: String
    var containerId: String
    var birdCount: Int
    var loadedAt: Date
}
