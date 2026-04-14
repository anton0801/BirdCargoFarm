import SwiftUI

// MARK: - Loading View
struct LoadingView: View {
    @EnvironmentObject var store: AppStore
    let plan: TransportPlan
    @State private var showAddLoading = false

    var assignments: [LoadingAssignment] { store.assignmentsFor(plan.id) }

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Summary
                    BCCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Loading Summary")
                                    .font(.bcHeadline)
                                    .foregroundColor(.bcText)
                                Text(plan.name)
                                    .font(.bcCaption)
                                    .foregroundColor(.bcTextSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(assignments.reduce(0) { $0 + $1.birdCount })")
                                    .font(.bcTitle2)
                                    .foregroundColor(.bcPrimary)
                                Text("loaded")
                                    .font(.bcCaption)
                                    .foregroundColor(.bcTextSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Container status
                    VStack(spacing: 10) {
                        BCSectionHeader(title: "Container Status").padding(.horizontal, 20)
                        ForEach(store.containers) { c in
                            ContainerRow(container: c)
                                .padding(.horizontal, 20)
                        }
                    }

                    // Assignments list
                    if !assignments.isEmpty {
                        VStack(spacing: 10) {
                            BCSectionHeader(title: "Loading Log").padding(.horizontal, 20)
                            ForEach(assignments) { a in
                                LoadingAssignmentRow(assignment: a)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    BCPrimaryButton(title: "Load Birds into Container") { showAddLoading = true }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Loading")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddLoading) {
            AddLoadingView(plan: plan)
        }
    }
}

struct LoadingAssignmentRow: View {
    @EnvironmentObject var store: AppStore
    let assignment: LoadingAssignment

    var birdGroup: BirdGroup? { store.birdGroups.first { $0.id == assignment.birdGroupId } }
    var container: BirdContainer? { store.containers.first { $0.id == assignment.containerId } }

    var body: some View {
        BCCard(padding: 14) {
            HStack(spacing: 12) {
                Text(birdGroup?.type.icon ?? "🐔")
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 3) {
                    Text(birdGroup?.name ?? "Unknown group")
                        .font(.bcCallout)
                        .foregroundColor(.bcText)
                    Text("→ \(container?.name ?? "Unknown container")")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(assignment.birdCount)")
                        .font(.bcTitle3)
                        .foregroundColor(.bcPrimary)
                    Text("birds")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextLight)
                }
            }
        }
    }
}

// MARK: - Add Loading Assignment
struct AddLoadingView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    let plan: TransportPlan

    @State private var selectedGroupId = ""
    @State private var selectedContainerId = ""
    @State private var birdCount = ""
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var selectedContainer: BirdContainer? {
        store.containers.first { $0.id == selectedContainerId }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.bcPrimary.opacity(0.12))
                            .frame(width: 70, height: 70)
                        Image(systemName: "arrow.down.to.line.compact")
                            .font(.system(size: 30))
                            .foregroundColor(.bcPrimary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bird Group").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            if store.birdGroups.isEmpty {
                                Text("No bird groups available. Add birds first.")
                                    .font(.bcCaption).foregroundColor(.bcError)
                            } else {
                                Picker("Bird Group", selection: $selectedGroupId) {
                                    Text("Select Group").tag("")
                                    ForEach(store.birdGroups) { g in
                                        Text("\(g.type.icon) \(g.name) (\(g.count) birds)").tag(g.id)
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
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Container").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            if store.containers.isEmpty {
                                Text("No containers available. Add containers first.")
                                    .font(.bcCaption).foregroundColor(.bcError)
                            } else {
                                Picker("Container", selection: $selectedContainerId) {
                                    Text("Select Container").tag("")
                                    ForEach(store.containers) { c in
                                        Text("\(c.name) (space: \(c.availableSpace))").tag(c.id)
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
                        }
                        if let c = selectedContainer {
                            BCCard(padding: 12) {
                                HStack {
                                    Text("Available space:")
                                        .font(.bcCallout)
                                        .foregroundColor(.bcTextSecondary)
                                    Spacer()
                                    Text("\(c.availableSpace) birds")
                                        .font(.bcHeadline)
                                        .foregroundColor(c.isFull ? .bcError : .bcSuccess)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Number of Birds to Load").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            BCTextField(placeholder: "e.g., 25", text: $birdCount, keyboardType: .numberPad, prefix: "🔢")
                        }
                    }
                    .padding(.horizontal, 20)

                    if !errorMessage.isEmpty {
                        Text(errorMessage).font(.bcCaption).foregroundColor(.bcError).padding(.horizontal, 20)
                    }

                    BCPrimaryButton(title: "Confirm Loading") { save() }
                        .padding(.horizontal, 20)
                    Spacer()
                }
            }
            .navigationTitle("Load Birds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
            .alert("Birds Loaded!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }

    func save() {
        guard !selectedGroupId.isEmpty, !selectedContainerId.isEmpty,
              let count = Int(birdCount), count > 0 else {
            errorMessage = "Please select group, container and enter a valid count."; return
        }
        if let c = selectedContainer, count > c.availableSpace {
            errorMessage = "Not enough space in container (available: \(c.availableSpace))."; return
        }
        let a = LoadingAssignment(
            transportPlanId: plan.id, birdGroupId: selectedGroupId,
            containerId: selectedContainerId, birdCount: count, loadedAt: Date()
        )
        store.addLoadingAssignment(a)
        showSuccess = true
    }
}

// MARK: - Route View
struct RouteView: View {
    @EnvironmentObject var store: AppStore
    let plan: TransportPlan
    @State private var showAddStop = false

    var stops: [RouteStop] { store.stopsFor(plan.id) }

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Route header
                    BCCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Label(plan.origin, systemImage: "arrow.up.circle.fill")
                                    .font(.bcCallout)
                                    .foregroundColor(.bcPrimary)
                                Label(plan.destination, systemImage: "flag.checkered.circle.fill")
                                    .font(.bcCallout)
                                    .foregroundColor(.bcAccentDark)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(stops.count)")
                                    .font(.bcTitle2)
                                    .foregroundColor(.bcPrimary)
                                Text("stops")
                                    .font(.bcCaption)
                                    .foregroundColor(.bcTextSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if stops.isEmpty {
                        BCEmptyState(icon: "map", title: "No route stops", subtitle: "Add rest stops, feed stops, or checkpoints.", actionTitle: "Add Stop") { showAddStop = true }
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                                RouteStopTimelineRow(stop: stop, isLast: index == stops.count - 1)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    BCSecondaryButton(title: "+ Add Route Stop") { showAddStop = true }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Route")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddStop) {
            AddRouteStopView(plan: plan)
        }
    }
}

struct RouteStopRow: View {
    @EnvironmentObject var store: AppStore
    let stop: RouteStop

    var body: some View {
        BCCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: stop.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(stop.completed ? .bcSuccess : .bcPrimary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(stop.name)
                        .font(.bcCallout)
                        .foregroundColor(.bcText)
                    Text(stop.type.rawValue)
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                }
                Spacer()
                Button(action: {
                    var updated = stop
                    updated.completed.toggle()
                    store.updateRouteStop(updated)
                }) {
                    Image(systemName: stop.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(stop.completed ? .bcSuccess : .bcTextLight)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct RouteStopTimelineRow: View {
    @EnvironmentObject var store: AppStore
    let stop: RouteStop
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(stop.completed ? Color.bcSuccess : Color.bcPrimary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: stop.type.icon)
                        .font(.system(size: 16))
                        .foregroundColor(stop.completed ? .white : .bcPrimary)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.bcDivider)
                        .frame(width: 2, height: 40)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name)
                    .font(.bcHeadline)
                    .foregroundColor(.bcText)
                Text(stop.type.rawValue)
                    .font(.bcCaption)
                    .foregroundColor(.bcTextSecondary)
                Text(stop.estimatedTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.bcCaption)
                    .foregroundColor(.bcTextLight)
                if !stop.notes.isEmpty {
                    Text(stop.notes).font(.bcCaption).foregroundColor(.bcTextSecondary)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, isLast ? 0 : 30)

            Spacer()

            Button(action: {
                var updated = stop
                updated.completed.toggle()
                store.updateRouteStop(updated)
            }) {
                Image(systemName: stop.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(stop.completed ? .bcSuccess : .bcTextLight)
                    .padding(.top, 6)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Add Route Stop
struct AddRouteStopView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    let plan: TransportPlan

    @State private var name = ""
    @State private var type: RouteStop.StopType = .rest
    @State private var estimatedTime = Date()
    @State private var notes = ""
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
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.bcSecondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Stop Name").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            BCTextField(placeholder: "e.g., Highway Rest Area", text: $name)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Stop Type").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            Picker("", selection: $type) {
                                ForEach(RouteStop.StopType.allCases, id: \.self) { t in
                                    Label(t.rawValue, systemImage: t.icon).tag(t)
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
                            Text("Estimated Time").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            DatePicker("", selection: $estimatedTime)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.bcBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bcDivider))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            BCTextField(placeholder: "Optional notes...", text: $notes)
                        }
                    }
                    .padding(.horizontal, 20)

                    BCPrimaryButton(title: "Add Stop") {
                        guard !name.isEmpty else { return }
                        let s = RouteStop(transportPlanId: plan.id, name: name, type: type, estimatedTime: estimatedTime, notes: notes)
                        store.addRouteStop(s)
                        showSuccess = true
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
            }
            .navigationTitle("Add Route Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
            .alert("Stop Added!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }
}

// MARK: - Conditions View
struct ConditionsView: View {
    @EnvironmentObject var store: AppStore
    let plan: TransportPlan
    @State private var showLog = false

    var logs: [ConditionLog] { store.logsFor(plan.id) }

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Latest reading
                    if let latest = logs.first {
                        BCCard {
                            VStack(spacing: 16) {
                                Text("Latest Reading")
                                    .font(.bcHeadline)
                                    .foregroundColor(.bcText)

                                HStack(spacing: 20) {
                                    conditionBlock(icon: "thermometer.medium", value: store.temperatureUnit == "Fahrenheit" ? "\(String(format: "%.1f", latest.temperature * 9/5 + 32))°F" : "\(String(format: "%.1f", latest.temperature))°C", label: "Temp", color: .bcAccent)
                                    conditionBlock(icon: "humidity", value: "\(String(format: "%.0f", latest.humidity))%", label: "Humidity", color: .bcSecondary)
                                    conditionBlock(icon: "wind", value: latest.ventilation.rawValue, label: "Ventilation", color: .bcPrimary)
                                }

                                Text("Recorded: \(latest.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.bcCaption)
                                    .foregroundColor(.bcTextLight)
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        BCEmptyState(icon: "thermometer.medium", title: "No readings yet", subtitle: "Log your first condition reading during transport.", actionTitle: "Log Conditions") { showLog = true }
                    }

                    // Log history
                    if !logs.isEmpty {
                        VStack(spacing: 10) {
                            BCSectionHeader(title: "Log History (\(logs.count))").padding(.horizontal, 20)
                            ForEach(logs) { log in
                                ConditionLogCard(log: log)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    BCPrimaryButton(title: "Log Current Conditions") { showLog = true }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Conditions")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLog) {
            AddConditionLogView(plan: plan)
        }
    }

    func conditionBlock(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 48, height: 48)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 20))
            }
            Text(value).font(.bcHeadline).foregroundColor(.bcText)
            Text(label).font(.bcCaption).foregroundColor(.bcTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ConditionLogCard: View {
    @EnvironmentObject var store: AppStore
    let log: ConditionLog

    var body: some View {
        BCCard(padding: 14) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 14) {
                        Label(store.temperatureUnit == "Fahrenheit" ? "\(String(format: "%.1f", log.temperature * 9/5 + 32))°F" : "\(String(format: "%.1f", log.temperature))°C", systemImage: "thermometer.medium")
                            .font(.bcCallout)
                            .foregroundColor(.bcAccent)
                        Label("\(String(format: "%.0f", log.humidity))%", systemImage: "humidity")
                            .font(.bcCallout)
                            .foregroundColor(.bcSecondary)
                    }
                    HStack(spacing: 6) {
                        Label(log.ventilation.rawValue, systemImage: "wind")
                            .font(.bcCaption)
                            .foregroundColor(.bcTextSecondary)
                        if !log.notes.isEmpty {
                            Text("• \(log.notes)")
                                .font(.bcCaption)
                                .foregroundColor(.bcTextSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.bcCaption)
                    .foregroundColor(.bcTextLight)
            }
        }
    }
}

// MARK: - Add Condition Log
struct AddConditionLogView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    let plan: TransportPlan

    @State private var temperature: Double = 20
    @State private var humidity: Double = 60
    @State private var ventilation: ConditionLog.VentilationLevel = .good
    @State private var notes = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle().fill(Color.bcAccent.opacity(0.12)).frame(width: 70, height: 70)
                            Image(systemName: "thermometer.medium").font(.system(size: 30)).foregroundColor(.bcAccent)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Temperature")
                                        .font(.bcCaptionBold)
                                        .foregroundColor(.bcTextSecondary)
                                    Spacer()
                                    Text(store.temperatureUnit == "Fahrenheit" ? "\(String(format: "%.1f", temperature * 9/5 + 32))°F" : "\(String(format: "%.1f", temperature))°C")
                                        .font(.bcHeadline)
                                        .foregroundColor(.bcAccent)
                                }
                                Slider(value: $temperature, in: -10...50, step: 0.5)
                                    .accentColor(.bcAccent)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Humidity")
                                        .font(.bcCaptionBold)
                                        .foregroundColor(.bcTextSecondary)
                                    Spacer()
                                    Text("\(String(format: "%.0f", humidity))%")
                                        .font(.bcHeadline)
                                        .foregroundColor(.bcSecondary)
                                }
                                Slider(value: $humidity, in: 0...100, step: 1)
                                    .accentColor(.bcSecondary)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ventilation").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                HStack(spacing: 8) {
                                    ForEach(ConditionLog.VentilationLevel.allCases, id: \.self) { v in
                                        Button(action: { ventilation = v }) {
                                            Text(v.rawValue)
                                                .font(.bcCaptionBold)
                                                .foregroundColor(ventilation == v ? .white : .bcTextSecondary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 8)
                                                .background(ventilation == v ? Color.bcPrimary : Color.bcDivider)
                                                .cornerRadius(10)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "Optional notes...", text: $notes)
                            }
                        }
                        .padding(.horizontal, 20)

                        BCPrimaryButton(title: "Save Log") {
                            let log = ConditionLog(
                                transportPlanId: plan.id, timestamp: Date(),
                                temperature: temperature, humidity: humidity,
                                ventilation: ventilation, notes: notes
                            )
                            store.addConditionLog(log)
                            showSuccess = true
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Log Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
            .alert("Conditions Logged!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }
}

// MARK: - Arrival View
struct ArrivalView: View {
    @EnvironmentObject var store: AppStore
    @State var plan: TransportPlan
    @State private var showHealthCheck = false

    var assignments: [LoadingAssignment] { store.assignmentsFor(plan.id) }

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Status
                    ZStack {
                        LinearGradient(colors: [plan.status == .arrived ? Color(hex: "#2D6A4F") : .bcAccentDark, plan.status == .arrived ? Color(hex: "#40916C") : .bcAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
                        VStack(spacing: 10) {
                            Image(systemName: plan.status == .arrived || plan.status == .completed ? "checkmark.circle.fill" : "clock.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                            Text(plan.status == .arrived || plan.status == .completed ? "Arrived!" : "In Transit")
                                .font(.bcTitle2)
                                .foregroundColor(.white)
                            Text(plan.destination)
                                .font(.bcBody)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(24)
                    }
                    .cornerRadius(20)
                    .padding(.horizontal, 20)

                    // Mark arrived
                    if plan.status != .arrived && plan.status != .completed {
                        BCPrimaryButton(title: "Mark as Arrived") {
                            var updated = plan
                            updated.status = .arrived
                            plan = updated
                            store.updateTransportPlan(updated)
                            store.logActivity("Transport arrived: \(plan.name)", icon: "checkmark.circle.fill", category: "Transport")
                        }
                        .padding(.horizontal, 20)
                    }

                    // Bird count summary
                    BCCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Arrival Summary")
                                .font(.bcHeadline)
                                .foregroundColor(.bcText)
                            HStack {
                                infoItem("Birds Expected", "\(plan.birdCount)")
                                Spacer()
                                infoItem("Containers", "\(Set(assignments.map { $0.containerId }).count)")
                                Spacer()
                                infoItem("Bird Groups", "\(Set(assignments.map { $0.birdGroupId }).count)")
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Health check on arrival
                    BCSecondaryButton(title: "Record Arrival Health Check") { showHealthCheck = true }
                        .padding(.horizontal, 20)

                    // Mark completed
                    if plan.status == .arrived {
                        BCPrimaryButton(title: "Complete Transport") {
                            var updated = plan
                            updated.status = .completed
                            plan = updated
                            store.updateTransportPlan(updated)
                            store.logActivity("Transport completed: \(plan.name)", icon: "star.fill", category: "Transport")
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Arrival")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showHealthCheck) {
            if let firstGroup = store.birdGroups.first(where: { g in store.assignmentsFor(plan.id).map { $0.birdGroupId }.contains(g.id) }) {
                AddHealthRecordView(birdGroupId: firstGroup.id)
            }
        }
    }

    func infoItem(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.bcTitle2).foregroundColor(.bcPrimary)
            Text(label).font(.bcCaption).foregroundColor(.bcTextSecondary)
        }
    }
}

// MARK: - Housing View
struct HousingView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                if store.housings.isEmpty {
                    BCEmptyState(icon: "house", title: "No housing", subtitle: "Add coops, barns, and pens.", actionTitle: "Add Housing") { showAdd = true }
                } else {
                    List {
                        ForEach(store.housings) { h in
                            NavigationLink(destination: HousingDetailView(housing: h)) {
                                HousingRow(housing: h)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { store.deleteHousing(store.housings[$0].id) }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.bcBackground)
                }
            }
            .navigationTitle("Housing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.bcPrimary)
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddHousingView() }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct HousingRow: View {
    let housing: Housing

    var fillPercent: Double {
        housing.capacity > 0 ? Double(housing.currentOccupancy) / Double(housing.capacity) : 0
    }

    var body: some View {
        BCCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.bcPrimary.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: "house.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.bcPrimary)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(housing.name)
                        .font(.bcHeadline)
                        .foregroundColor(.bcText)
                    Text(housing.type.rawValue)
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.bcDivider).frame(height: 5)
                            RoundedRectangle(cornerRadius: 3).fill(Color.bcSecondary).frame(width: geo.size.width * CGFloat(min(fillPercent, 1)), height: 5)
                        }
                    }
                    .frame(height: 5)
                    Text("\(housing.currentOccupancy) / \(housing.capacity)")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                }
                Spacer()
                Text("\(housing.availableSpace)")
                    .font(.bcTitle3)
                    .foregroundColor(.bcSecondary)
                Text("free")
                    .font(.bcCaption)
                    .foregroundColor(.bcTextLight)
            }
        }
    }
}

struct HousingDetailView: View {
    @EnvironmentObject var store: AppStore
    @State var housing: Housing
    @State private var showEdit = false

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    BCCard {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle().fill(Color.bcPrimary.opacity(0.1)).frame(width: 80, height: 80)
                                Image(systemName: "house.fill").font(.system(size: 36)).foregroundColor(.bcPrimary)
                            }
                            Text(housing.name).font(.bcTitle2).foregroundColor(.bcText)
                            Text(housing.type.rawValue).font(.bcBody).foregroundColor(.bcTextSecondary)

                            HStack(spacing: 30) {
                                VStack { Text("\(housing.capacity)").font(.bcTitle2).foregroundColor(.bcText); Text("Capacity").font(.bcCaption).foregroundColor(.bcTextSecondary) }
                                VStack { Text("\(housing.currentOccupancy)").font(.bcTitle2).foregroundColor(.bcAccent); Text("Current").font(.bcCaption).foregroundColor(.bcTextSecondary) }
                                VStack { Text("\(housing.availableSpace)").font(.bcTitle2).foregroundColor(.bcSuccess); Text("Available").font(.bcCaption).foregroundColor(.bcTextSecondary) }
                            }

                            if !housing.notes.isEmpty {
                                Text(housing.notes).font(.bcBody).foregroundColor(.bcTextSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Adjust occupancy
                    BCCard {
                        VStack(spacing: 12) {
                            Text("Update Occupancy").font(.bcHeadline).foregroundColor(.bcText)
                            HStack(spacing: 20) {
                                Button(action: {
                                    if housing.currentOccupancy > 0 {
                                        housing.currentOccupancy -= 1
                                        store.updateHousing(housing)
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.bcAccentDark)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Text("\(housing.currentOccupancy)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.bcText)
                                    .frame(minWidth: 80)

                                Button(action: {
                                    if housing.currentOccupancy < housing.capacity {
                                        housing.currentOccupancy += 1
                                        store.updateHousing(housing)
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.bcSecondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    BCSecondaryButton(title: "Edit Housing") { showEdit = true }
                        .padding(.horizontal, 20)
                    Spacer(minLength: 30)
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle(housing.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) { EditHousingView(housing: $housing) }
    }
}

struct AddHousingView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var capacity = ""
    @State private var occupancy = ""
    @State private var type: Housing.HousingType = .coop
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
                            Circle().fill(Color.bcPrimary.opacity(0.12)).frame(width: 70, height: 70)
                            Image(systemName: "house.fill").font(.system(size: 30)).foregroundColor(.bcPrimary)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Housing Name").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "e.g., Main Coop A", text: $name)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Type").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                Picker("", selection: $type) {
                                    ForEach(Housing.HousingType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                                }.pickerStyle(.segmented)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Capacity").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "e.g., 200", text: $capacity, keyboardType: .numberPad, prefix: "🔢")
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Current Occupancy").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "e.g., 0", text: $occupancy, keyboardType: .numberPad, prefix: "🐔")
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "Optional...", text: $notes)
                            }
                        }
                        .padding(.horizontal, 20)

                        if !errorMessage.isEmpty {
                            Text(errorMessage).font(.bcCaption).foregroundColor(.bcError).padding(.horizontal, 20)
                        }

                        BCPrimaryButton(title: "Add Housing") {
                            guard !name.isEmpty, let cap = Int(capacity), cap > 0 else {
                                errorMessage = "Please enter name and valid capacity."; return
                            }
                            let h = Housing(name: name, capacity: cap, currentOccupancy: Int(occupancy) ?? 0, type: type, notes: notes)
                            store.addHousing(h)
                            showSuccess = true
                        }
                        .padding(.horizontal, 20).padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Add Housing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
            .alert("Housing Added!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }
}

struct EditHousingView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    @Binding var housing: Housing
    @State private var name: String
    @State private var capacity: String
    @State private var notes: String

    init(housing: Binding<Housing>) {
        _housing = housing
        _name = State(initialValue: housing.wrappedValue.name)
        _capacity = State(initialValue: "\(housing.wrappedValue.capacity)")
        _notes = State(initialValue: housing.wrappedValue.notes)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                VStack(spacing: 14) {
                    BCTextField(placeholder: "Housing Name", text: $name).padding(.horizontal, 20)
                    BCTextField(placeholder: "Capacity", text: $capacity, keyboardType: .numberPad).padding(.horizontal, 20)
                    BCTextField(placeholder: "Notes", text: $notes).padding(.horizontal, 20)
                    BCPrimaryButton(title: "Save") {
                        var updated = housing
                        updated.name = name
                        updated.capacity = Int(capacity) ?? housing.capacity
                        updated.notes = notes
                        housing = updated
                        store.updateHousing(updated)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Edit Housing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
        }
    }
}
