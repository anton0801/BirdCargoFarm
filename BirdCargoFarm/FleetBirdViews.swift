import SwiftUI

// MARK: - Birds & Containers Tab
struct BirdsContainersTabView: View {
    @State private var selectedSection = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segment
                    Picker("", selection: $selectedSection) {
                        Text("Bird Groups").tag(0)
                        Text("Containers").tag(1)
                        Text("Vehicles").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    if selectedSection == 0 {
                        BirdGroupsView()
                    } else if selectedSection == 1 {
                        ContainersView()
                    } else {
                        VehiclesView()
                    }
                }
            }
            .navigationTitle("Fleet & Birds")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Bird Groups
struct BirdGroupsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var filterType: BirdGroup.BirdType? = nil

    var filtered: [BirdGroup] {
        filterType == nil ? store.birdGroups : store.birdGroups.filter { $0.type == filterType }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", selected: filterType == nil) { filterType = nil }
                    ForEach(BirdGroup.BirdType.allCases, id: \.self) { t in
                        FilterChip(title: "\(t.icon) \(t.rawValue)", selected: filterType == t) {
                            filterType = filterType == t ? nil : t
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            if filtered.isEmpty {
                Spacer()
                BCEmptyState(icon: "bird", title: "No bird groups", subtitle: "Add your first bird group.", actionTitle: "Add Group") { showAdd = true }
                Spacer()
            } else {
                List {
                    ForEach(filtered) { group in
                        NavigationLink(destination: BirdGroupDetailView(group: group)) {
                            BirdGroupRow(group: group)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { store.deleteBirdGroup(filtered[$0].id) }
                    }
                }
                .listStyle(.plain)
                .background(Color.bcBackground)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.bcPrimary)
                        .font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddBirdGroupView()
        }
    }
}

struct BirdGroupRow: View {
    let group: BirdGroup

    var body: some View {
        BCCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.bcSecondary.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Text(group.type.icon)
                        .font(.system(size: 26))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.bcHeadline)
                        .foregroundColor(.bcText)
                    Text("\(group.type.rawValue) • \(group.count) birds • \(group.age)w old")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                }
                Spacer()
                healthBadge(group.healthStatus)
            }
        }
    }

    func healthBadge(_ status: BirdGroup.HealthStatus) -> some View {
        let color: Color
        switch status {
        case .healthy: color = .bcSuccess
        case .monitor: color = .bcWarning
        case .sick: color = .bcError
        }
        return BCStatusBadge(text: status.rawValue, color: color)
    }
}

// MARK: - Add Bird Group
struct AddBirdGroupView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var type: BirdGroup.BirdType = .chicken
    @State private var count = ""
    @State private var age = ""
    @State private var weight = ""
    @State private var notes = ""
    @State private var healthStatus: BirdGroup.HealthStatus = .healthy
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Emoji display
                        Text(type.icon)
                            .font(.system(size: 64))
                            .padding(.top, 10)

                        VStack(spacing: 14) {
                            formField("Group Name") {
                                BCTextField(placeholder: "e.g., Batch A Chickens", text: $name)
                            }
                            formField("Bird Type") {
                                Picker("Bird Type", selection: $type) {
                                    ForEach(BirdGroup.BirdType.allCases, id: \.self) { t in
                                        Text("\(t.icon) \(t.rawValue)").tag(t)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.bcBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bcDivider))
                            }
                            formField("Number of Birds") {
                                BCTextField(placeholder: "e.g., 100", text: $count, keyboardType: .numberPad, prefix: "🔢")
                            }
                            formField("Age (weeks)") {
                                BCTextField(placeholder: "e.g., 12", text: $age, keyboardType: .numberPad, prefix: "📅")
                            }
                            formField("Avg Weight (kg)") {
                                BCTextField(placeholder: "e.g., 1.8", text: $weight, keyboardType: .decimalPad, prefix: "⚖️")
                            }
                            formField("Health Status") {
                                Picker("Health", selection: $healthStatus) {
                                    ForEach(BirdGroup.HealthStatus.allCases, id: \.self) { s in
                                        Text(s.rawValue).tag(s)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            formField("Notes (Optional)") {
                                BCTextField(placeholder: "Additional info...", text: $notes)
                            }
                        }
                        .padding(.horizontal, 20)

                        if !errorMessage.isEmpty {
                            Text(errorMessage).font(.bcCaption).foregroundColor(.bcError).padding(.horizontal, 20)
                        }

                        BCPrimaryButton(title: "Add Bird Group") { save() }
                            .padding(.horizontal, 20).padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Add Bird Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
            .alert("Bird Group Added!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }

    @ViewBuilder
    func formField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
            content()
        }
    }

    func save() {
        guard !name.isEmpty, let c = Int(count), c > 0 else {
            errorMessage = "Please enter name and valid bird count."; return
        }
        let g = BirdGroup(
            name: name, type: type, count: c,
            age: Int(age) ?? 0, weightKg: Double(weight) ?? 0,
            notes: notes, healthStatus: healthStatus
        )
        store.addBirdGroup(g)
        showSuccess = true
    }
}

// MARK: - Bird Group Detail
struct BirdGroupDetailView: View {
    @EnvironmentObject var store: AppStore
    @State var group: BirdGroup
    @State private var showEdit = false
    @State private var showHealthCheck = false

    var healthRecords: [HealthRecord] { store.recordsFor(group.id) }

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    BCCard {
                        VStack(spacing: 16) {
                            Text(group.type.icon)
                                .font(.system(size: 56))
                            Text(group.name)
                                .font(.bcTitle2)
                                .foregroundColor(.bcText)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                infoBlock(label: "Count", value: "\(group.count)")
                                infoBlock(label: "Age", value: "\(group.age)w")
                                infoBlock(label: "Weight", value: "\(String(format: "%.1f", group.weightKg))kg")
                            }

                            HStack {
                                Text("Health:")
                                    .font(.bcCallout)
                                    .foregroundColor(.bcTextSecondary)
                                Picker("", selection: Binding(
                                    get: { group.healthStatus },
                                    set: { newVal in
                                        var updated = group
                                        updated.healthStatus = newVal
                                        group = updated
                                        store.updateBirdGroup(updated)
                                    }
                                )) {
                                    ForEach(BirdGroup.HealthStatus.allCases, id: \.self) { s in
                                        Text(s.rawValue).tag(s)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    BCPrimaryButton(title: "Record Health Check") { showHealthCheck = true }
                        .padding(.horizontal, 20)

                    if !healthRecords.isEmpty {
                        VStack(spacing: 10) {
                            BCSectionHeader(title: "Health History").padding(.horizontal, 20)
                            ForEach(healthRecords) { rec in
                                HealthRecordRow(record: rec)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showHealthCheck) {
            AddHealthRecordView(birdGroupId: group.id)
        }
    }

    func infoBlock(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.bcTitle2).foregroundColor(.bcText)
            Text(label).font(.bcCaption).foregroundColor(.bcTextSecondary)
        }
    }
}

struct HealthRecordRow: View {
    let record: HealthRecord

    var body: some View {
        BCCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "cross.case.fill")
                    .foregroundColor(.bcSecondary)
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.checkType.rawValue)
                        .font(.bcCallout)
                        .foregroundColor(.bcText)
                    Text(record.condition)
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                }
                Spacer()
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.bcCaption)
                    .foregroundColor(.bcTextLight)
            }
        }
    }
}

// MARK: - Add Health Record
struct AddHealthRecordView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    let birdGroupId: String
    @State private var condition = ""
    @State private var notes = ""
    @State private var checkType: HealthRecord.CheckType = .preDeparture
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.bcSecondary.opacity(0.12))
                            .frame(width: 70, height: 70)
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.bcSecondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Check Type").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            Picker("", selection: $checkType) {
                                ForEach(HealthRecord.CheckType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.bcBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bcDivider))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Condition").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            BCTextField(placeholder: "e.g., All birds healthy, active...", text: $condition)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            BCTextField(placeholder: "Additional notes...", text: $notes)
                        }
                    }
                    .padding(.horizontal, 20)

                    BCPrimaryButton(title: "Save Health Record") {
                        guard !condition.isEmpty else { return }
                        let rec = HealthRecord(
                            birdGroupId: birdGroupId, date: Date(),
                            condition: condition, notes: notes, checkType: checkType
                        )
                        store.addHealthRecord(rec)
                        showSuccess = true
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Health Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
            .alert("Saved!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }
}

// MARK: - Containers View
struct ContainersView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false

    var body: some View {
        VStack {
            if store.containers.isEmpty {
                Spacer()
                BCEmptyState(icon: "shippingbox", title: "No containers", subtitle: "Add cages and crates for transport.", actionTitle: "Add Container") { showAdd = true }
                Spacer()
            } else {
                List {
                    ForEach(store.containers) { c in
                        ContainerRow(container: c)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { store.deleteContainer(store.containers[$0].id) }
                    }
                }
                .listStyle(.plain)
                .background(Color.bcBackground)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.bcPrimary)
                        .font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddContainerView()
        }
    }
}

struct ContainerRow: View {
    let container: BirdContainer

    var fillColor: Color {
        switch container.status {
        case .empty: return .bcTextLight
        case .partial: return .bcAccent
        case .full: return .bcAccentDark
        case .inTransit: return .bcSecondary
        }
    }

    var body: some View {
        BCCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(fillColor.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 22))
                        .foregroundColor(fillColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(container.name)
                        .font(.bcHeadline)
                        .foregroundColor(.bcText)
                    Text("\(container.type.rawValue) • Capacity: \(container.capacity)")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                    // Occupancy bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.bcDivider)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(fillColor)
                                .frame(width: geo.size.width * CGFloat(container.occupancyPercent), height: 6)
                        }
                    }
                    .frame(height: 6)
                    Text("\(container.currentLoad) / \(container.capacity) birds")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                }
                Spacer()
                BCStatusBadge(text: container.status.rawValue, color: fillColor)
            }
        }
    }
}

// MARK: - Add Container
struct AddContainerView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var capacity = ""
    @State private var type: BirdContainer.ContainerType = .cage
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.bcAccent.opacity(0.12))
                            .frame(width: 70, height: 70)
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.bcAccent)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Container Name").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            BCTextField(placeholder: "e.g., Cage-01", text: $name)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Type").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            Picker("", selection: $type) {
                                ForEach(BirdContainer.ContainerType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Capacity (birds)").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            BCTextField(placeholder: "e.g., 30", text: $capacity, keyboardType: .numberPad, prefix: "🔢")
                        }
                    }
                    .padding(.horizontal, 20)

                    if !errorMessage.isEmpty {
                        Text(errorMessage).font(.bcCaption).foregroundColor(.bcError).padding(.horizontal, 20)
                    }

                    BCPrimaryButton(title: "Add Container") { save() }
                        .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Add Container")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
            .alert("Container Added!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }

    func save() {
        guard !name.isEmpty, let cap = Int(capacity), cap > 0 else {
            errorMessage = "Please enter name and valid capacity."; return
        }
        let c = BirdContainer(name: name, capacity: cap, currentLoad: 0, type: type, status: .empty)
        store.addContainer(c)
        showSuccess = true
    }
}

// MARK: - Vehicles View
struct VehiclesView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false

    var body: some View {
        VStack {
            if store.vehicles.isEmpty {
                Spacer()
                BCEmptyState(icon: "truck.box", title: "No vehicles", subtitle: "Add your transport vehicles.", actionTitle: "Add Vehicle") { showAdd = true }
                Spacer()
            } else {
                List {
                    ForEach(store.vehicles) { v in
                        NavigationLink(destination: VehicleDetailView(vehicle: v)) {
                            VehicleRow(vehicle: v)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { store.deleteVehicle(store.vehicles[$0].id) }
                    }
                }
                .listStyle(.plain)
                .background(Color.bcBackground)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.bcPrimary)
                        .font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddVehicleView()
        }
    }
}

struct VehicleRow: View {
    let vehicle: Vehicle

    var body: some View {
        BCCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.bcPrimary.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.bcPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.name)
                        .font(.bcHeadline)
                        .foregroundColor(.bcText)
                    Text("\(vehicle.type.rawValue) • \(vehicle.plateNumber)")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(vehicle.capacity)")
                        .font(.bcTitle3)
                        .foregroundColor(.bcPrimary)
                    Text("capacity")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextLight)
                }
            }
        }
    }
}

struct VehicleDetailView: View {
    @EnvironmentObject var store: AppStore
    @State var vehicle: Vehicle
    @State private var showEdit = false

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    BCCard {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.bcGradientStart, .bcGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "truck.box.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }
                            Text(vehicle.name)
                                .font(.bcTitle2)
                                .foregroundColor(.bcText)
                            Text(vehicle.plateNumber)
                                .font(.bcBody)
                                .foregroundColor(.bcTextSecondary)

                            Divider()

                            HStack {
                                infoItem("Type", vehicle.type.rawValue)
                                Spacer()
                                infoItem("Capacity", "\(vehicle.capacity) birds")
                            }

                            if !vehicle.notes.isEmpty {
                                Text(vehicle.notes)
                                    .font(.bcBody)
                                    .foregroundColor(.bcTextSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    BCPrimaryButton(title: "Edit Vehicle") { showEdit = true }
                        .padding(.horizontal, 20)
                    Spacer(minLength: 30)
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle(vehicle.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            EditVehicleView(vehicle: $vehicle)
        }
    }

    func infoItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.bcCaption).foregroundColor(.bcTextSecondary)
            Text(value).font(.bcHeadline).foregroundColor(.bcText)
        }
    }
}

struct AddVehicleView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var type: Vehicle.VehicleType = .truck
    @State private var plateNumber = ""
    @State private var capacity = ""
    @State private var notes = ""
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.bcPrimary.opacity(0.12))
                                .frame(width: 70, height: 70)
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.bcPrimary)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Vehicle Name").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "e.g., Farm Truck #1", text: $name)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Vehicle Type").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                Picker("", selection: $type) {
                                    ForEach(Vehicle.VehicleType.allCases, id: \.self) { t in
                                        Text(t.rawValue).tag(t)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Plate Number").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "e.g., ABC-1234", text: $plateNumber, prefix: "🚗")
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bird Capacity").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "e.g., 500", text: $capacity, keyboardType: .numberPad, prefix: "🔢")
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "Optional notes...", text: $notes)
                            }
                        }
                        .padding(.horizontal, 20)

                        if !errorMessage.isEmpty {
                            Text(errorMessage).font(.bcCaption).foregroundColor(.bcError).padding(.horizontal, 20)
                        }

                        BCPrimaryButton(title: "Add Vehicle") { save() }
                            .padding(.horizontal, 20).padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
            .alert("Vehicle Added!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }

    func save() {
        guard !name.isEmpty, !plateNumber.isEmpty, let cap = Int(capacity) else {
            errorMessage = "Please fill in all required fields."; return
        }
        let v = Vehicle(name: name, type: type, plateNumber: plateNumber, capacity: cap, notes: notes)
        store.addVehicle(v)
        showSuccess = true
    }
}

struct EditVehicleView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    @Binding var vehicle: Vehicle

    @State private var name: String
    @State private var plateNumber: String
    @State private var capacity: String
    @State private var notes: String

    init(vehicle: Binding<Vehicle>) {
        _vehicle = vehicle
        _name = State(initialValue: vehicle.wrappedValue.name)
        _plateNumber = State(initialValue: vehicle.wrappedValue.plateNumber)
        _capacity = State(initialValue: "\(vehicle.wrappedValue.capacity)")
        _notes = State(initialValue: vehicle.wrappedValue.notes)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    VStack(spacing: 14) {
                        BCTextField(placeholder: "Vehicle Name", text: $name)
                        BCTextField(placeholder: "Plate Number", text: $plateNumber)
                        BCTextField(placeholder: "Capacity", text: $capacity, keyboardType: .numberPad)
                        BCTextField(placeholder: "Notes", text: $notes)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    BCPrimaryButton(title: "Save") { save() }
                        .padding(.horizontal, 20)
                    Spacer()
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
        }
    }

    func save() {
        var updated = vehicle
        updated.name = name
        updated.plateNumber = plateNumber
        updated.capacity = Int(capacity) ?? vehicle.capacity
        updated.notes = notes
        vehicle = updated
        store.updateVehicle(updated)
        presentationMode.wrappedValue.dismiss()
    }
}
