import SwiftUI

// MARK: - Transport Plans List
struct TransportPlansView: View {
    @EnvironmentObject var store: AppStore
    @State private var showCreate = false
    @State private var searchText = ""
    @State private var filterStatus: TransportPlan.TransportStatus? = nil

    var filtered: [TransportPlan] {
        store.transportPlans.filter {
            (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) ||
             $0.destination.localizedCaseInsensitiveContains(searchText)) &&
            (filterStatus == nil || $0.status == filterStatus)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.bcTextSecondary)
                        TextField("Search transports...", text: $searchText)
                            .font(.bcBody)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.bcSurface)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All", selected: filterStatus == nil) {
                                filterStatus = nil
                            }
                            ForEach(TransportPlan.TransportStatus.allCases, id: \.self) { s in
                                FilterChip(title: s.rawValue, selected: filterStatus == s) {
                                    filterStatus = filterStatus == s ? nil : s
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }

                    if filtered.isEmpty {
                        Spacer()
                        BCEmptyState(
                            icon: "truck.box",
                            title: "No transport plans",
                            subtitle: "Create your first plan to start tracking poultry transport.",
                            actionTitle: "New Plan"
                        ) { showCreate = true }
                        Spacer()
                    } else {
                        List {
                            ForEach(filtered) { plan in
                                NavigationLink(destination: TransportDetailView(plan: plan)) {
                                    TransportListRow(plan: plan)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { store.deleteTransportPlan(filtered[$0].id) }
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.bcBackground)
                    }
                }
            }
            .navigationTitle("Transport Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreate = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.bcPrimary)
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateTransportView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bcCaptionBold)
                .foregroundColor(selected ? .white : .bcTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? Color.bcPrimary : Color.bcSurface)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(selected ? Color.clear : Color.bcDivider, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TransportListRow: View {
    let plan: TransportPlan

    var body: some View {
        BCCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: plan.status.color).opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: plan.status.color))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(plan.name)
                        .font(.bcHeadline)
                        .foregroundColor(.bcText)
                    Text("\(plan.origin) → \(plan.destination)")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                    HStack(spacing: 10) {
                        Label("\(plan.birdCount)", systemImage: "bird.fill")
                            .font(.bcCaption)
                            .foregroundColor(.bcTextSecondary)
                        Text(plan.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.bcCaption)
                            .foregroundColor(.bcTextSecondary)
                    }
                }
                Spacer()
                BCStatusBadge(text: plan.status.rawValue, color: Color(hex: plan.status.color))
            }
        }
    }
}

// MARK: - Create Transport
struct CreateTransportView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var date = Date().addingTimeInterval(86400)
    @State private var origin = ""
    @State private var destination = ""
    @State private var birdCount = ""
    @State private var notes = ""
    @State private var selectedVehicleId = ""
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.bcGradientStart, .bcGradientEnd],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 70, height: 70)
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)

                        VStack(spacing: 14) {
                            fieldSection("Transport Name") {
                                BCTextField(placeholder: "e.g., Spring Market Run", text: $name)
                            }
                            fieldSection("Date") {
                                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(.horizontal, 16)
                                    .frame(height: 52)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.bcBackground)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bcDivider, lineWidth: 1))
                            }
                            fieldSection("Origin") {
                                BCTextField(placeholder: "Farm location", text: $origin, prefix: "📍")
                            }
                            fieldSection("Destination") {
                                BCTextField(placeholder: "Delivery location", text: $destination, prefix: "🏁")
                            }
                            fieldSection("Bird Count") {
                                BCTextField(placeholder: "Total number of birds", text: $birdCount, keyboardType: .numberPad, prefix: "🐔")
                            }
                            if !store.vehicles.isEmpty {
                                fieldSection("Vehicle (Optional)") {
                                    Picker("Vehicle", selection: $selectedVehicleId) {
                                        Text("None").tag("")
                                        ForEach(store.vehicles) { v in
                                            Text(v.name).tag(v.id)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(.horizontal, 16)
                                    .frame(height: 52)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.bcBackground)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bcDivider, lineWidth: 1))
                                }
                            }
                            fieldSection("Notes (Optional)") {
                                ZStack(alignment: .topLeading) {
                                    if notes.isEmpty {
                                        Text("Any additional notes...")
                                            .font(.bcBody)
                                            .foregroundColor(.bcTextLight)
                                            .padding(16)
                                    }
                                    TextEditor(text: $notes)
                                        .font(.bcBody)
                                        .frame(height: 80)
                                        .padding(8)
                                }
                                .background(Color.bcBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bcDivider, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20)

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.bcCaption)
                                .foregroundColor(.bcError)
                                .padding(.horizontal, 20)
                        }

                        BCPrimaryButton(title: "Create Transport Plan") { save() }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("New Transport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.bcPrimary)
                }
            }
            .alert("Transport Created!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            } message: {
                Text("Your transport plan has been saved successfully.")
            }
        }
    }

    @ViewBuilder
    func fieldSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.bcCaptionBold)
                .foregroundColor(.bcTextSecondary)
            content()
        }
    }

    func save() {
        guard !name.isEmpty, !origin.isEmpty, !destination.isEmpty else {
            errorMessage = "Please fill in name, origin and destination."
            return
        }
        let count = Int(birdCount) ?? 0
        let plan = TransportPlan(
            name: name, date: date, origin: origin, destination: destination,
            birdCount: count, status: .planned,
            vehicleId: selectedVehicleId.isEmpty ? nil : selectedVehicleId,
            notes: notes
        )
        store.addTransportPlan(plan)
        showSuccess = true
    }
}

// MARK: - Transport Detail
struct TransportDetailView: View {
    @EnvironmentObject var store: AppStore
    @State var plan: TransportPlan
    @State private var showEdit = false
    @State private var showLoading = false
    @State private var showRoute = false
    @State private var showConditions = false
    @State private var showArrival = false

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero card
                    ZStack {
                        LinearGradient(colors: [.bcGradientStart, .bcGradientEnd],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                BCStatusBadge(text: plan.status.rawValue, color: .white)
                                Spacer()
                                Text(plan.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.bcCaption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Text(plan.name)
                                .font(.bcTitle2)
                                .foregroundColor(.white)
                            HStack {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(plan.origin) → \(plan.destination)")
                                    .font(.bcBody)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            HStack(spacing: 20) {
                                Label("\(plan.birdCount) birds", systemImage: "bird.fill")
                                    .font(.bcCallout)
                                    .foregroundColor(.white)
                                if let vid = plan.vehicleId,
                                   let vehicle = store.vehicles.first(where: { $0.id == vid }) {
                                    Label(vehicle.name, systemImage: "truck.box.fill")
                                        .font(.bcCallout)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(20)
                    }
                    .cornerRadius(20)
                    .padding(.horizontal, 20)

                    // Status changer
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Update Status")
                            .font(.bcCaptionBold)
                            .foregroundColor(.bcTextSecondary)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(TransportPlan.TransportStatus.allCases, id: \.self) { status in
                                    Button(action: {
                                        var updated = plan
                                        updated.status = status
                                        plan = updated
                                        store.updateTransportPlan(updated)
                                    }) {
                                        Text(status.rawValue)
                                            .font(.bcCaptionBold)
                                            .foregroundColor(plan.status == status ? .white : Color(hex: status.color))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(plan.status == status ? Color(hex: status.color) : Color(hex: status.color).opacity(0.12))
                                            .cornerRadius(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        BCSectionHeader(title: "Actions")
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            NavigationLink(destination: LoadingView(plan: plan)) {
                                ActionCard(icon: "arrow.down.to.line.compact", title: "Loading", color: .bcPrimary)
                            }
                            .buttonStyle(PlainButtonStyle())

                            NavigationLink(destination: RouteView(plan: plan)) {
                                ActionCard(icon: "map.fill", title: "Route", color: .bcSecondary)
                            }
                            .buttonStyle(PlainButtonStyle())

                            NavigationLink(destination: ConditionsView(plan: plan)) {
                                ActionCard(icon: "thermometer.medium", title: "Conditions", color: .bcAccent)
                            }
                            .buttonStyle(PlainButtonStyle())

                            NavigationLink(destination: ArrivalView(plan: plan)) {
                                ActionCard(icon: "checkmark.circle.fill", title: "Arrival", color: .bcAccentDark)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                    }

                    // Route Stops
                    let stops = store.stopsFor(plan.id)
                    if !stops.isEmpty {
                        VStack(spacing: 10) {
                            BCSectionHeader(title: "Route Stops (\(stops.count))")
                                .padding(.horizontal, 20)
                            ForEach(stops) { stop in
                                RouteStopRow(stop: stop)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Conditions
                    let logs = store.logsFor(plan.id)
                    if !logs.isEmpty {
                        VStack(spacing: 10) {
                            BCSectionHeader(title: "Latest Conditions")
                                .padding(.horizontal, 20)
                            if let latest = logs.first {
                                ConditionLogCard(log: latest)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    if !plan.notes.isEmpty {
                        BCCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.bcCaptionBold)
                                    .foregroundColor(.bcTextSecondary)
                                Text(plan.notes)
                                    .font(.bcBody)
                                    .foregroundColor(.bcText)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEdit = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.bcPrimary)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditTransportView(plan: $plan)
        }
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        BCCard {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.bcCallout)
                    .foregroundColor(.bcText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Edit Transport
struct EditTransportView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    @Binding var plan: TransportPlan

    @State private var name: String
    @State private var date: Date
    @State private var origin: String
    @State private var destination: String
    @State private var birdCount: String
    @State private var notes: String

    init(plan: Binding<TransportPlan>) {
        _plan = plan
        _name = State(initialValue: plan.wrappedValue.name)
        _date = State(initialValue: plan.wrappedValue.date)
        _origin = State(initialValue: plan.wrappedValue.origin)
        _destination = State(initialValue: plan.wrappedValue.destination)
        _birdCount = State(initialValue: "\(plan.wrappedValue.birdCount)")
        _notes = State(initialValue: plan.wrappedValue.notes)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 14) {
                            BCTextField(placeholder: "Transport Name", text: $name)
                            DatePicker("Date", selection: $date, displayedComponents: [.date])
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(Color.bcBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bcDivider))
                            BCTextField(placeholder: "Origin", text: $origin, prefix: "📍")
                            BCTextField(placeholder: "Destination", text: $destination, prefix: "🏁")
                            BCTextField(placeholder: "Bird Count", text: $birdCount, keyboardType: .numberPad, prefix: "🐔")
                            BCTextField(placeholder: "Notes", text: $notes)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        BCPrimaryButton(title: "Save Changes") { save() }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Edit Transport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.bcPrimary)
                }
            }
        }
    }

    func save() {
        var updated = plan
        updated.name = name
        updated.date = date
        updated.origin = origin
        updated.destination = destination
        updated.birdCount = Int(birdCount) ?? plan.birdCount
        updated.notes = notes
        plan = updated
        store.updateTransportPlan(updated)
        presentationMode.wrappedValue.dismiss()
    }
}
