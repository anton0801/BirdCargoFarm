import SwiftUI
import WebKit
// MARK: - Tasks & Calendar Tab
struct TasksCalendarTabView: View {
    @State private var selectedSection = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("", selection: $selectedSection) {
                        Text("Tasks").tag(0)
                        Text("Calendar").tag(1)
                        Text("Supplies").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    if selectedSection == 0 {
                        TasksView()
                    } else if selectedSection == 1 {
                        CalendarView()
                    } else {
                        SuppliesView()
                    }
                }
            }
            .navigationTitle("Tasks & Supplies")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var showCompleted = false

    var pending: [TransportTask] { store.tasks.filter { !$0.completed }.sorted { $0.dueDate < $1.dueDate } }
    var completed: [TransportTask] { store.tasks.filter { $0.completed } }

    var body: some View {
        VStack(spacing: 0) {
            if store.tasks.isEmpty {
                Spacer()
                BCEmptyState(icon: "checklist", title: "No tasks", subtitle: "Add tasks to prepare for transport.", actionTitle: "Add Task") { showAdd = true }
                Spacer()
            } else {
                List {
                    if !pending.isEmpty {
                        Section(header: Text("Pending (\(pending.count))").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)) {
                            ForEach(pending) { task in
                                TaskRowView(task: task)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { store.deleteTask(pending[$0].id) }
                            }
                        }
                    }
                    if !completed.isEmpty {
                        Section(header:
                            Button(action: { withAnimation { showCompleted.toggle() } }) {
                                HStack {
                                    Text("Completed (\(completed.count))")
                                        .font(.bcCaptionBold)
                                        .foregroundColor(.bcTextSecondary)
                                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11))
                                        .foregroundColor(.bcTextSecondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        ) {
                            if showCompleted {
                                ForEach(completed) { task in
                                    TaskRowView(task: task)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                        .opacity(0.6)
                                }
                                .onDelete { indexSet in
                                    indexSet.forEach { store.deleteTask(completed[$0].id) }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.bcBackground)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.bcPrimary)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddTaskView() }
    }
}

// MARK: - Add Task
struct AddTaskView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    @State private var title = ""
    @State private var dueDate = Date().addingTimeInterval(3600)
    @State private var priority: TransportTask.Priority = .medium
    @State private var notes = ""
    @State private var selectedPlanId = ""
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle().fill(Color.bcAccentDark.opacity(0.12)).frame(width: 70, height: 70)
                            Image(systemName: "checklist").font(.system(size: 30)).foregroundColor(.bcAccentDark)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Task").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "e.g., Prepare containers", text: $title)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Due Date & Time").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                DatePicker("", selection: $dueDate)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(.horizontal, 16)
                                    .frame(height: 52)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.bcBackground)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bcDivider))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Priority").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                HStack(spacing: 10) {
                                    ForEach(TransportTask.Priority.allCases, id: \.self) { p in
                                        Button(action: { priority = p }) {
                                            Text(p.rawValue)
                                                .font(.bcCaptionBold)
                                                .foregroundColor(priority == p ? .white : Color(hex: p.color))
                                                .padding(.horizontal, 16).padding(.vertical, 8)
                                                .background(priority == p ? Color(hex: p.color) : Color(hex: p.color).opacity(0.12))
                                                .cornerRadius(20)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            if !store.transportPlans.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Transport (Optional)").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                    Picker("", selection: $selectedPlanId) {
                                        Text("None").tag("")
                                        ForEach(store.transportPlans) { p in Text(p.name).tag(p.id) }
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
                                Text("Notes").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "Optional...", text: $notes)
                            }
                        }
                        .padding(.horizontal, 20)

                        if !errorMessage.isEmpty { Text(errorMessage).font(.bcCaption).foregroundColor(.bcError).padding(.horizontal, 20) }

                        BCPrimaryButton(title: "Add Task") {
                            guard !title.isEmpty else { errorMessage = "Enter a task title."; return }
                            let t = TransportTask(title: title, dueDate: dueDate, priority: priority, transportPlanId: selectedPlanId.isEmpty ? nil : selectedPlanId, notes: notes)
                            store.addTask(t)
                            showSuccess = true
                        }
                        .padding(.horizontal, 20).padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
            .alert("Task Added!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedDate = Date()

    var plansOnDate: [TransportPlan] {
        store.transportPlans.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    var tasksOnDate: [TransportTask] {
        store.tasks.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: selectedDate) }
    }

    var body: some View {
        VStack(spacing: 0) {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .accentColor(.bcPrimary)
                .padding(.horizontal, 16)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    if plansOnDate.isEmpty && tasksOnDate.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 36))
                                .foregroundColor(.bcTextLight)
                            Text("Nothing on \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.bcBody)
                                .foregroundColor(.bcTextSecondary)
                        }
                        .padding(30)
                    } else {
                        if !plansOnDate.isEmpty {
                            VStack(spacing: 8) {
                                BCSectionHeader(title: "Transports").padding(.horizontal, 20)
                                ForEach(plansOnDate) { plan in
                                    TransportListRow(plan: plan).padding(.horizontal, 20)
                                }
                            }
                        }
                        if !tasksOnDate.isEmpty {
                            VStack(spacing: 8) {
                                BCSectionHeader(title: "Tasks").padding(.horizontal, 20)
                                ForEach(tasksOnDate) { task in
                                    TaskRowView(task: task).padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
        }
    }
}



extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [BirdCargo] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view)
        let translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}


// MARK: - Supplies View
struct SuppliesView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false

    var feedTotal: Double { store.supplies.filter { $0.type == .feed }.reduce(0) { $0 + $1.quantity } }
    var waterTotal: Double { store.supplies.filter { $0.type == .water }.reduce(0) { $0 + $1.quantity } }

    var body: some View {
        VStack(spacing: 0) {
            // Summary
            HStack(spacing: 12) {
                supplyBlock(icon: "🌾", label: "Feed", value: "\(String(format: "%.1f", feedTotal)) kg", color: .bcAccent)
                supplyBlock(icon: "💧", label: "Water", value: "\(String(format: "%.1f", waterTotal)) L", color: .bcSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            if store.supplies.isEmpty {
                Spacer()
                BCEmptyState(icon: "bag", title: "No supplies", subtitle: "Track feed, water, and equipment.", actionTitle: "Add Supply") { showAdd = true }
                Spacer()
            } else {
                List {
                    ForEach(store.supplies) { s in
                        SupplyRow(supply: s)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { store.deleteSupply(store.supplies[$0].id) }
                    }
                }
                .listStyle(.plain)
                .background(Color.bcBackground)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.bcPrimary)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddSupplyView() }
    }

    func supplyBlock(icon: String, label: String, value: String, color: Color) -> some View {
        BCCard {
            HStack(spacing: 10) {
                Text(icon).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(value).font(.bcHeadline).foregroundColor(.bcText)
                    Text(label).font(.bcCaption).foregroundColor(.bcTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SupplyRow: View {
    @EnvironmentObject var store: AppStore
    let supply: Supply

    var icon: String {
        switch supply.type {
        case .feed: return "🌾"
        case .water: return "💧"
        case .medicine: return "💊"
        case .equipment: return "🔧"
        }
    }

    var body: some View {
        BCCard(padding: 14) {
            HStack(spacing: 12) {
                Text(icon).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 3) {
                    Text(supply.name).font(.bcCallout).foregroundColor(.bcText)
                    Text(supply.type.rawValue).font(.bcCaption).foregroundColor(.bcTextSecondary)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(String(format: supply.quantity == supply.quantity.rounded() ? "%.0f" : "%.1f", supply.quantity))")
                        .font(.bcTitle3).foregroundColor(.bcPrimary)
                    Text(supply.unit).font(.bcCaption).foregroundColor(.bcTextSecondary)
                }
            }
        }
    }
}

struct AddSupplyView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var type: Supply.SupplyType = .feed
    @State private var quantity = ""
    @State private var unit = "kg"
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(Color.bcAccent.opacity(0.12)).frame(width: 70, height: 70)
                        Image(systemName: "bag.fill").font(.system(size: 30)).foregroundColor(.bcAccent)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Supply Name").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            BCTextField(placeholder: "e.g., Poultry Feed", text: $name)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Type").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                            Picker("", selection: $type) {
                                ForEach(Supply.SupplyType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: type) { t in
                                switch t {
                                case .feed: unit = "kg"
                                case .water: unit = "L"
                                case .medicine: unit = "doses"
                                case .equipment: unit = "pcs"
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Quantity").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "0", text: $quantity, keyboardType: .decimalPad)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Unit").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "kg", text: $unit)
                            }
                            .frame(width: 80)
                        }
                    }
                    .padding(.horizontal, 20)

                    if !errorMessage.isEmpty { Text(errorMessage).font(.bcCaption).foregroundColor(.bcError).padding(.horizontal, 20) }

                    BCPrimaryButton(title: "Add Supply") {
                        guard !name.isEmpty, let qty = Double(quantity) else { errorMessage = "Enter name and quantity."; return }
                        store.addSupply(Supply(name: name, type: type, quantity: qty, unit: unit))
                        showSuccess = true
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
            }
            .navigationTitle("Add Supply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.bcPrimary)
                }
            }
            .alert("Supply Added!", isPresented: $showSuccess) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }
}

// MARK: - More Tab
struct MoreTabView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()
                List {
                    Section {
                        NavigationLink(destination: HousingView()) {
                            MoreRow(icon: "house.fill", title: "Housing", color: .bcPrimary)
                        }
                        NavigationLink(destination: ReportsView()) {
                            MoreRow(icon: "chart.bar.fill", title: "Reports", color: .bcSecondary)
                        }
                        NavigationLink(destination: ActivityHistoryView()) {
                            MoreRow(icon: "clock.fill", title: "Activity History", color: .bcAccent)
                        }
                    }
                    .listRowBackground(Color.bcSurface)

                    Section {
                        NavigationLink(destination: ProfileView()) {
                            MoreRow(icon: "person.fill", title: "Profile", color: .bcAccentDark)
                        }
                        NavigationLink(destination: SettingsView()) {
                            MoreRow(icon: "gearshape.fill", title: "Settings", color: Color(hex: "#6C757D"))
                        }
                    }
                    .listRowBackground(Color.bcSurface)
                }
                .listStyle(.insetGrouped)
                .background(Color.bcBackground)
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MoreRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.bcBody)
                .foregroundColor(.bcText)
        }
        .padding(.vertical, 4)
    }
}
final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "birdcargo_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("🐦 [BirdCargo] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

// MARK: - Reports
struct ReportsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    BCCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Transport Report")
                                    .font(.bcTitle2)
                                    .foregroundColor(.bcText)
                                Text(store.currentUser?.farm ?? "Your Farm")
                                    .font(.bcCaption)
                                    .foregroundColor(.bcTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.bcSecondary)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        StatCard(title: "Total Transports", value: "\(store.transportCount)", icon: "truck.box.fill", color: .bcPrimary)
                        StatCard(title: "Completed", value: "\(store.completedTransports)", icon: "checkmark.circle.fill", color: .bcSuccess)
                        StatCard(title: "Birds Transported", value: "\(store.totalBirdsTransported)", icon: "bird.fill", color: .bcSecondary)
                        StatCard(title: "Bird Health %", value: "\(String(format: "%.0f", store.healthyBirdPercent))%", icon: "cross.case.fill", color: .bcAccent)
                    }
                    .padding(.horizontal, 20)

                    // Transport breakdown
                    BCCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Status Breakdown").font(.bcHeadline).foregroundColor(.bcText)
                            ForEach(TransportPlan.TransportStatus.allCases, id: \.self) { status in
                                let count = store.transportPlans.filter { $0.status == status }.count
                                HStack {
                                    Circle().fill(Color(hex: status.color)).frame(width: 10, height: 10)
                                    Text(status.rawValue).font(.bcBody).foregroundColor(.bcText)
                                    Spacer()
                                    Text("\(count)").font(.bcHeadline).foregroundColor(Color(hex: status.color))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Bird groups breakdown
                    BCCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Bird Groups by Type").font(.bcHeadline).foregroundColor(.bcText)
                            ForEach(BirdGroup.BirdType.allCases, id: \.self) { type in
                                let groups = store.birdGroups.filter { $0.type == type }
                                if !groups.isEmpty {
                                    HStack {
                                        Text(type.icon).font(.system(size: 20))
                                        Text(type.rawValue).font(.bcBody).foregroundColor(.bcText)
                                        Spacer()
                                        Text("\(groups.reduce(0) { $0 + $1.count }) birds")
                                            .font(.bcCallout)
                                            .foregroundColor(.bcPrimary)
                                    }
                                }
                            }
                            if store.birdGroups.isEmpty {
                                Text("No bird groups yet").font(.bcBody).foregroundColor(.bcTextSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        BCCard {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 40, height: 40)
                    Image(systemName: icon).font(.system(size: 18, weight: .medium)).foregroundColor(color)
                }
                Text(value).font(.bcTitle1).foregroundColor(.bcText)
                Text(title).font(.bcCaption).foregroundColor(.bcTextSecondary).lineLimit(2)
            }
        }
    }
}

// MARK: - Activity History
struct ActivityHistoryView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            if store.activities.isEmpty {
                BCEmptyState(icon: "clock", title: "No activity yet", subtitle: "Actions you take will appear here.")
            } else {
                List {
                    ForEach(store.activities) { a in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(Color.bcPrimary.opacity(0.1)).frame(width: 40, height: 40)
                                Image(systemName: a.icon).font(.system(size: 16)).foregroundColor(.bcPrimary)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(a.action).font(.bcCallout).foregroundColor(.bcText)
                                Text(a.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.bcCaption).foregroundColor(.bcTextSecondary)
                            }
                            Spacer()
                            BCStatusBadge(text: a.category, color: .bcTextSecondary)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .background(Color.bcBackground)
            }
        }
        .navigationTitle("Activity History")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var name: String = ""
    @State private var farm: String = ""
    @State private var isEditing = false
    @State private var showSavedAlert = false

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.bcGradientStart, .bcGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)
                        Text(String(store.currentUser?.name.prefix(1) ?? "F"))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)

                    if isEditing {
                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Name").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "Your name", text: $name)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Farm Name").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)
                                BCTextField(placeholder: "Your farm", text: $farm, prefix: "🌾")
                            }
                        }
                        .padding(.horizontal, 20)

                        HStack(spacing: 12) {
                            BCSecondaryButton(title: "Cancel") { isEditing = false }
                            BCPrimaryButton(title: "Save") {
                                store.updateProfile(name: name, farm: farm)
                                isEditing = false
                                showSavedAlert = true
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        BCCard {
                            VStack(spacing: 12) {
                                Text(store.currentUser?.name ?? "Farmer")
                                    .font(.bcTitle2)
                                    .foregroundColor(.bcText)
                                Label(store.currentUser?.farm ?? "Farm", systemImage: "leaf.fill")
                                    .font(.bcBody)
                                    .foregroundColor(.bcSecondary)
                                Label(store.currentUser?.email ?? "", systemImage: "envelope.fill")
                                    .font(.bcBody)
                                    .foregroundColor(.bcTextSecondary)
                            }
                        }
                        .padding(.horizontal, 20)

                        BCSecondaryButton(title: "Edit Profile") {
                            name = store.currentUser?.name ?? ""
                            farm = store.currentUser?.farm ?? ""
                            isEditing = true
                        }
                        .padding(.horizontal, 20)
                    }

                    // Stats
                    BCCard {
                        VStack(spacing: 12) {
                            Text("My Stats").font(.bcHeadline).foregroundColor(.bcText)
                            Divider()
                            HStack {
                                statItem("Transports", "\(store.transportCount)")
                                Spacer()
                                statItem("Bird Groups", "\(store.birdGroups.count)")
                                Spacer()
                                statItem("Vehicles", "\(store.vehicles.count)")
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 30)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .alert("Profile Updated!", isPresented: $showSavedAlert) {
            Button("OK") { }
        }
        .onAppear {
            name = store.currentUser?.name ?? ""
            farm = store.currentUser?.farm ?? ""
        }
    }

    func statItem(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.bcTitle2).foregroundColor(.bcPrimary)
            Text(label).font(.bcCaption).foregroundColor(.bcTextSecondary)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false
    @State private var showSaved = false

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()
            List {
                // Appearance
                Section(header: Text("Appearance").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Theme").font(.bcCallout).foregroundColor(.bcText)
                        Picker("Theme", selection: Binding(
                            get: { store.themeMode },
                            set: { store.themeMode = $0 }
                        )) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.bcSurface)
                    .padding(.vertical, 6)
                }

                // Units
                Section(header: Text("Units").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)) {
                    HStack {
                        Image(systemName: "thermometer.medium")
                            .foregroundColor(.bcAccent)
                            .frame(width: 28)
                        Picker("Temperature", selection: Binding(
                            get: { store.temperatureUnit },
                            set: { store.temperatureUnit = $0 }
                        )) {
                            Text("Celsius (°C)").tag("Celsius")
                            Text("Fahrenheit (°F)").tag("Fahrenheit")
                        }
                        .pickerStyle(.menu)
                    }
                    .listRowBackground(Color.bcSurface)
                }

                // Notifications
                Section(header: Text("Notifications").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)) {
                    Toggle(isOn: Binding(
                        get: { store.notificationsEnabled },
                        set: { store.notificationsEnabled = $0 }
                    )) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.bcPrimary)
                                .frame(width: 28)
                            Text("Push Notifications")
                                .font(.bcBody)
                                .foregroundColor(.bcText)
                        }
                    }
                    .tint(.bcPrimary)
                    .listRowBackground(Color.bcSurface)
                }

                // Account
                Section(header: Text("Account").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)) {
                    Button(action: { showLogoutConfirm = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.bcAccent)
                                .frame(width: 28)
                            Text("Log Out")
                                .font(.bcBody)
                                .foregroundColor(.bcAccent)
                        }
                    }
                    .listRowBackground(Color.bcSurface)

                    Button(action: { showDeleteConfirm = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .foregroundColor(.bcError)
                                .frame(width: 28)
                            Text("Delete Account")
                                .font(.bcBody)
                                .foregroundColor(.bcError)
                        }
                    }
                    .listRowBackground(Color.bcSurface)
                }

                // App info
                Section(header: Text("About").font(.bcCaptionBold).foregroundColor(.bcTextSecondary)) {
                    HStack {
                        Image(systemName: "bird.fill").foregroundColor(.bcPrimary).frame(width: 28)
                        Text("Bird Cargo Farm").font(.bcBody).foregroundColor(.bcText)
                        Spacer()
                        Text("v1.0.0").font(.bcCaption).foregroundColor(.bcTextSecondary)
                    }
                    .listRowBackground(Color.bcSurface)
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.bcBackground)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Log Out", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { store.logout() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) { store.deleteAccount() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your account and all data. This cannot be undone.")
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup)
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:)))
        gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture)
        popup.addGestureRecognizer(gesture)
        popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            popup.load(navigationAction.request)
        }
        return popup
    }
    
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView)
        let velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed:
            if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose {
                UIView.animate(withDuration: 0.25, animations: {
                    popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0)
                }) { [weak self] _ in self?.dismissTopPopup() }
            } else {
                UIView.animate(withDuration: 0.2) { popupView.transform = .identity }
            }
        default: break
        }
    }
    
    private func dismissTopPopup() {
        guard let last = popups.last else { return }
        last.removeFromSuperview()
        popups.removeLast()
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if let index = popups.firstIndex(of: webView) {
            webView.removeFromSuperview()
            popups.remove(at: index)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
