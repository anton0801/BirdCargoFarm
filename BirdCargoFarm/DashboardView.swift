import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Dashboard")
                }
                .tag(0)

            TransportPlansView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "truck.box.fill" : "truck.box")
                    Text("Transport")
                }
                .tag(1)

            BirdsContainersTabView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "bird.fill" : "bird")
                    Text("Birds")
                }
                .tag(2)

            TasksCalendarTabView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "checklist" : "checklist")
                    Text("Tasks")
                }
                .tag(3)

            MoreTabView()
                .tabItem {
                    Image(systemName: "ellipsis.circle\(selectedTab == 4 ? ".fill" : "")")
                    Text("More")
                }
                .tag(4)
        }
        .accentColor(.bcPrimary)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @State private var animateCards = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 4) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Good \(timeGreeting())")
                                        .font(.bcCallout)
                                        .foregroundColor(.bcTextSecondary)
                                    Text(store.currentUser?.name ?? "Farmer")
                                        .font(.bcTitle1)
                                        .foregroundColor(.bcText)
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.bcGradientStart, .bcGradientEnd],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 46, height: 46)
                                    Text(String(store.currentUser?.name.prefix(1) ?? "F"))
                                        .font(.bcTitle3)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Farm badge
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.bcSecondary)
                            Text(store.currentUser?.farm ?? "Your Farm")
                                .font(.bcCaptionBold)
                                .foregroundColor(.bcSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.bcSecondary.opacity(0.1))
                        .cornerRadius(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            DashboardStatCard(
                                title: "Active Transports",
                                value: "\(store.activePlans.count)",
                                icon: "truck.box.fill",
                                color: .bcPrimary,
                                delay: 0
                            )
                            DashboardStatCard(
                                title: "Bird Groups",
                                value: "\(store.birdGroups.count)",
                                icon: "bird.fill",
                                color: .bcSecondary,
                                delay: 0.05
                            )
                            DashboardStatCard(
                                title: "Containers Used",
                                value: "\(store.containersInUse) / \(store.containers.count)",
                                icon: "shippingbox.fill",
                                color: .bcAccent,
                                delay: 0.1
                            )
                            DashboardStatCard(
                                title: "Pending Tasks",
                                value: "\(store.pendingTasks.count)",
                                icon: "checklist",
                                color: .bcAccentDark,
                                delay: 0.15
                            )
                        }
                        .padding(.horizontal, 20)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)

                        // Active Transports
                        if !store.activePlans.isEmpty {
                            VStack(spacing: 12) {
                                BCSectionHeader(title: "Active Transport")
                                    .padding(.horizontal, 20)
                                ForEach(store.activePlans) { plan in
                                    NavigationLink(destination: TransportDetailView(plan: plan)) {
                                        TransportPlanCard(plan: plan)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Upcoming
                        if !store.upcomingPlans.isEmpty {
                            VStack(spacing: 12) {
                                BCSectionHeader(title: "Upcoming", actionTitle: "See All") {
                                }
                                .padding(.horizontal, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(store.upcomingPlans.prefix(5)) { plan in
                                            NavigationLink(destination: TransportDetailView(plan: plan)) {
                                                UpcomingPlanCard(plan: plan)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        // Pending Tasks
                        if !store.pendingTasks.isEmpty {
                            VStack(spacing: 12) {
                                BCSectionHeader(title: "Pending Tasks")
                                    .padding(.horizontal, 20)

                                ForEach(store.pendingTasks.prefix(3)) { task in
                                    TaskRowView(task: task)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Empty state
                        if store.transportPlans.isEmpty {
                            BCCard {
                                BCEmptyState(
                                    icon: "truck.box",
                                    title: "No transports yet",
                                    subtitle: "Create your first transport plan to get started.",
                                    actionTitle: "Create Transport"
                                ) {}
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }
        }
    }

    func timeGreeting() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "morning," }
        if h < 17 { return "afternoon," }
        return "evening,"
    }
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let delay: Double

    @State private var appeared = false

    var body: some View {
        BCCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(color)
                    }
                    Spacer()
                }
                Text(value)
                    .font(.bcTitle1)
                    .foregroundColor(.bcText)
                Text(title)
                    .font(.bcCaption)
                    .foregroundColor(.bcTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                appeared = true
            }
        }
    }
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                Image("ii_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 2)
                    .opacity(0.8)
                
                Image("ii_a_img")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}


struct TransportPlanCard: View {
    let plan: TransportPlan

    var body: some View {
        BCCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.bcHeadline)
                            .foregroundColor(.bcText)
                        Text("\(plan.origin) → \(plan.destination)")
                            .font(.bcCaption)
                            .foregroundColor(.bcTextSecondary)
                    }
                    Spacer()
                    BCStatusBadge(text: plan.status.rawValue,
                                  color: Color(hex: plan.status.color))
                }
                HStack(spacing: 16) {
                    Label("\(plan.birdCount) birds", systemImage: "bird.fill")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                    Label(plan.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                }
            }
        }
    }
}

struct UpcomingPlanCard: View {
    let plan: TransportPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [.bcGradientStart, .bcGradientEnd],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                Image(systemName: "truck.box.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 22))
            }
            Text(plan.name)
                .font(.bcCallout)
                .foregroundColor(.bcText)
                .lineLimit(2)
            Text(plan.date.formatted(date: .abbreviated, time: .omitted))
                .font(.bcCaption)
                .foregroundColor(.bcTextSecondary)
            Text("\(plan.birdCount) birds")
                .font(.bcCaptionBold)
                .foregroundColor(.bcPrimary)
        }
        .frame(width: 140)
        .padding(14)
        .background(Color.bcSurface)
        .cornerRadius(16)
        .shadow(color: Color.bcText.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

struct TaskRowView: View {
    @EnvironmentObject var store: AppStore
    let task: TransportTask

    var body: some View {
        BCCard(padding: 14) {
            HStack(spacing: 12) {
                Button(action: { store.toggleTask(task.id) }) {
                    ZStack {
                        Circle()
                            .stroke(Color(hex: task.priority.color), lineWidth: 2)
                            .frame(width: 26, height: 26)
                        if task.completed {
                            Circle()
                                .fill(Color(hex: task.priority.color))
                                .frame(width: 26, height: 26)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.bcCallout)
                        .foregroundColor(.bcText)
                        .strikethrough(task.completed)
                    Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.bcCaption)
                        .foregroundColor(.bcTextSecondary)
                }
                Spacer()
                BCStatusBadge(text: task.priority.rawValue, color: Color(hex: task.priority.color))
            }
        }
    }
}
