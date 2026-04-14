import SwiftUI

// MARK: - Splash Screen
struct SplashView: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var truckOffset: CGFloat = -60
    @State private var birdOffset: CGFloat = 60
    @State private var subtitleOpacity: Double = 0
    @State private var waveScale: CGFloat = 0
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.bcGradientStart, Color.bcGradientEnd],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -200)
                .scaleEffect(waveScale)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 200, height: 200)
                .offset(x: 120, y: 250)
                .scaleEffect(waveScale)

            VStack(spacing: 24) {
                // Logo
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)

                    VStack(spacing: 0) {
                        HStack(spacing: -8) {
                            Image(systemName: "bird.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color.bcAccent)
                                .offset(x: birdOffset, y: -4)
                                .opacity(opacity)

                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: truckOffset)
                                .opacity(opacity)
                        }
                    }
                }
                .scaleEffect(scale)

                VStack(spacing: 8) {
                    Text("Bird Cargo Farm")
                        .font(.bcLargeTitle)
                        .foregroundColor(.white)
                        .opacity(opacity)

                    Text("Transport poultry safely.")
                        .font(.bcCallout)
                        .foregroundColor(.white.opacity(0.75))
                        .opacity(subtitleOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
                scale = 1.0
                opacity = 1
                truckOffset = 0
                birdOffset = 0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
                subtitleOpacity = 1
                waveScale = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                onFinish()
            }
        }
    }
}

// MARK: - Welcome Screen
struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var animateIn = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bcBackground.ignoresSafeArea()

                // Background decoration
                VStack {
                    ZStack {
                        LinearGradient(colors: [.bcGradientStart, .bcGradientEnd],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        VStack {
                            Spacer()
                            WaveShape()
                                .fill(Color.bcBackground)
                                .frame(height: 80)
                        }
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    Spacer()
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Illustration
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 110, height: 110)
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "bird.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.bcAccent)
                                    Image(systemName: "truck.box.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .scaleEffect(animateIn ? 1 : 0.5)
                        .opacity(animateIn ? 1 : 0)

                        Text("Bird Cargo Farm")
                            .font(.bcTitle1)
                            .foregroundColor(.white)
                            .opacity(animateIn ? 1 : 0)

                        Text("Plan. Track. Deliver safely.")
                            .font(.bcBody)
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(animateIn ? 1 : 0)
                    }
                    .padding(.bottom, 60)

                    Spacer()

                    // Buttons
                    VStack(spacing: 14) {
                        NavigationLink(destination: LoginView(), isActive: $showLogin) {
                            EmptyView()
                        }
                        NavigationLink(destination: RegisterView(), isActive: $showRegister) {
                            EmptyView()
                        }

                        BCPrimaryButton(title: "Log In") { showLogin = true }
                        BCSecondaryButton(title: "Create Account") { showRegister = true }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .offset(y: animateIn ? 0 : 40)
                    .opacity(animateIn ? 1 : 0)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                    animateIn = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        path.addCurve(to: CGPoint(x: rect.width, y: rect.height * 0.5),
                      control1: CGPoint(x: rect.width * 0.3, y: 0),
                      control2: CGPoint(x: rect.width * 0.7, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Register View
struct RegisterView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(.bcPrimary)
                        Text("Create Account")
                            .font(.bcTitle1)
                            .foregroundColor(.bcText)
                        Text("Start managing your poultry transport")
                            .font(.bcBody)
                            .foregroundColor(.bcTextSecondary)
                    }
                    .padding(.top, 20)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)

                    // Form
                    VStack(spacing: 14) {
                        BCTextField(placeholder: "Full Name", text: $name, prefix: "👤")
                        BCTextField(placeholder: "Email Address", text: $email, keyboardType: .emailAddress, prefix: "✉️")
                        BCTextField(placeholder: "Password", text: $password, isSecure: true, prefix: "🔒")

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.bcCaption)
                                .foregroundColor(.bcError)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)

                    BCPrimaryButton(title: "Create Account", isLoading: isLoading) {
                        register()
                    }
                    .opacity(animateIn ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
    }

    func register() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            store.register(name: name, email: email, password: password) { success, msg in
                isLoading = false
                if !success { errorMessage = msg }
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color.bcBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.bcGradientStart, .bcGradientEnd],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                            Image(systemName: "bird.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Text("Welcome Back")
                            .font(.bcTitle1)
                            .foregroundColor(.bcText)
                        Text("Log in to your farm account")
                            .font(.bcBody)
                            .foregroundColor(.bcTextSecondary)
                    }
                    .padding(.top, 20)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)

                    // Form
                    VStack(spacing: 14) {
                        BCTextField(placeholder: "Email Address", text: $email, keyboardType: .emailAddress, prefix: "✉️")
                        BCTextField(placeholder: "Password", text: $password, isSecure: true, prefix: "🔒")

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.bcCaption)
                                .foregroundColor(.bcError)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .opacity(animateIn ? 1 : 0)

                    // Login + Demo buttons
                    VStack(spacing: 12) {
                        BCPrimaryButton(title: "Log In", isLoading: isLoading) {
                            loginAction()
                        }

                        // Demo button - prominent
                        Button(action: { store.loginDemo() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 18))
                                Text("Try Demo Account")
                                    .font(.bcHeadline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(colors: [.bcAccentDark, .bcAccent],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(14)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text("Demo account includes sample data")
                            .font(.bcCaption)
                            .foregroundColor(.bcTextLight)
                    }
                    .opacity(animateIn ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
    }

    func loginAction() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            store.login(email: email, password: password) { success, msg in
                isLoading = false
                if !success { errorMessage = msg }
            }
        }
    }
}
