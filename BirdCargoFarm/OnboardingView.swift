import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Plan Poultry Transport",
            subtitle: "Create detailed transport plans with routes, vehicles, and bird groups — all in one place.",
            icon: "map.fill",
            accentIcon: "truck.box.fill",
            color1: Color(hex: "#2D6A4F"),
            color2: Color(hex: "#40916C"),
            particles: ["🐔", "🦆", "🪿"]
        ),
        OnboardingPage(
            title: "Track Birds in Transit",
            subtitle: "Monitor temperature, humidity, and ventilation. Know exactly where each bird is at all times.",
            icon: "thermometer.medium",
            accentIcon: "bird.fill",
            color1: Color(hex: "#1B4332"),
            color2: Color(hex: "#2D6A4F"),
            particles: ["📍", "🌡️", "💨"]
        ),
        OnboardingPage(
            title: "Manage Arrival & Housing",
            subtitle: "Record health checks on arrival and assign birds to housing with capacity tracking.",
            icon: "house.fill",
            accentIcon: "checkmark.seal.fill",
            color1: Color(hex: "#40916C"),
            color2: Color(hex: "#52B788"),
            particles: ["🏠", "✅", "📋"]
        )
    ]

    var body: some View {
        ZStack {
            // Page background
            LinearGradient(colors: [pages[currentPage].color1, pages[currentPage].color2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            // Floating particles
            ParticleLayer(emojis: pages[currentPage].particles)
                .animation(.easeInOut(duration: 0.4), value: currentPage)

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation { hasCompletedOnboarding = true }
                    }
                    .font(.bcCallout)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(20)
                }

                Spacer()

                // Main illustration
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 200, height: 200)

                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 160, height: 160)

                    VStack(spacing: 8) {
                        Image(systemName: pages[currentPage].icon)
                            .font(.system(size: 52, weight: .medium))
                            .foregroundColor(.white)

                        Image(systemName: pages[currentPage].accentIcon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Color.bcAccent)
                    }
                }
                .id(currentPage)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.7).combined(with: .opacity),
                    removal: .scale(scale: 1.2).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPage)

                Spacer()

                // Text content
                VStack(spacing: 16) {
                    Text(pages[currentPage].title)
                        .font(.bcTitle1)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .id("title\(currentPage)")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                    Text(pages[currentPage].subtitle)
                        .font(.bcBody)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .id("sub\(currentPage)")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: currentPage)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Dots + Button
                VStack(spacing: 28) {
                    HStack(spacing: 10) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(Color.white.opacity(i == currentPage ? 1 : 0.4))
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            withAnimation { hasCompletedOnboarding = true }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                                .font(.bcHeadline)
                            Image(systemName: currentPage == pages.count - 1 ? "checkmark" : "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(pages[currentPage].color1)
                        .frame(width: 180, height: 52)
                        .background(Color.white)
                        .cornerRadius(26)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 50)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 && currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentPage += 1 }
                    } else if value.translation.width > 50 && currentPage > 0 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentPage -= 1 }
                    }
                }
        )
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let accentIcon: String
    let color1: Color
    let color2: Color
    let particles: [String]
}

struct ParticleLayer: View {
    let emojis: [String]
    @State private var offsets: [(CGFloat, CGFloat)] = []
    @State private var opacities: [Double] = []
    @State private var scales: [CGFloat] = []

    var body: some View {
        ZStack {
            ForEach(0..<min(emojis.count * 3, 9), id: \.self) { i in
                Text(emojis[i % emojis.count])
                    .font(.system(size: 22))
                    .offset(x: i < offsets.count ? offsets[i].0 : 0,
                            y: i < offsets.count ? offsets[i].1 : 0)
                    .opacity(i < opacities.count ? opacities[i] : 0)
                    .scaleEffect(i < scales.count ? scales[i] : 0.5)
            }
        }
        .onAppear { setup() }
        .onChange(of: emojis) { _ in setup() }
    }

    func setup() {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        offsets = (0..<9).map { _ in
            (CGFloat.random(in: -w/2...w/2), CGFloat.random(in: -h/2.5...h/2.5))
        }
        withAnimation(.easeIn(duration: 0.8)) {
            opacities = (0..<9).map { _ in Double.random(in: 0.1...0.3) }
            scales = (0..<9).map { _ in CGFloat.random(in: 0.6...1.2) }
        }
    }
}
