import SwiftUI

// MARK: - Color Palette
extension Color {
    static let bcPrimary       = Color(hex: "#2D6A4F")   // Deep forest green
    static let bcSecondary     = Color(hex: "#52B788")   // Fresh leaf green
    static let bcAccent        = Color(hex: "#F4A261")   // Warm amber/orange
    static let bcAccentDark    = Color(hex: "#E76F51")   // Terracotta
    static let bcBackground    = Color(hex: "#F8F5F0")   // Warm cream
    static let bcSurface       = Color(hex: "#FFFFFF")
    static let bcSurfaceDark   = Color(hex: "#1A2F23")
    static let bcText          = Color(hex: "#1B2D1E")
    static let bcTextSecondary = Color(hex: "#5A7A60")
    static let bcTextLight     = Color(hex: "#9BB8A0")
    static let bcDivider       = Color(hex: "#E0EBE3")
    static let bcWarning       = Color(hex: "#F4A261")
    static let bcError         = Color(hex: "#E76F51")
    static let bcSuccess       = Color(hex: "#52B788")

    static let bcGradientStart = Color(hex: "#2D6A4F")
    static let bcGradientEnd   = Color(hex: "#40916C")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Typography
extension Font {
    static let bcLargeTitle  = Font.system(size: 34, weight: .bold, design: .rounded)
    static let bcTitle1      = Font.system(size: 28, weight: .bold, design: .rounded)
    static let bcTitle2      = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let bcTitle3      = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let bcHeadline    = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let bcBody        = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bcCallout     = Font.system(size: 14, weight: .medium, design: .rounded)
    static let bcCaption     = Font.system(size: 12, weight: .regular, design: .rounded)
    static let bcCaptionBold = Font.system(size: 12, weight: .semibold, design: .rounded)
}

// MARK: - Shared UI Components

struct BCCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.bcSurface)
            .cornerRadius(16)
            .shadow(color: Color.bcText.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct BCPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false

    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                } else {
                    Text(title)
                        .font(.bcHeadline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(colors: [.bcGradientStart, .bcGradientEnd],
                               startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(14)
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BCSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bcHeadline)
                .foregroundColor(.bcPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.bcPrimary.opacity(0.1))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.bcPrimary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BCTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var prefix: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let prefix = prefix {
                Text(prefix)
                    .font(.bcBody)
                    .foregroundColor(.bcTextSecondary)
            }
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.bcBody)
                    .foregroundColor(.bcText)
            } else {
                TextField(placeholder, text: $text)
                    .font(.bcBody)
                    .foregroundColor(.bcText)
                    .keyboardType(keyboardType)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.bcBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.bcDivider, lineWidth: 1)
        )
    }
}

struct BCSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.bcTitle3)
                .foregroundColor(.bcText)
            Spacer()
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.bcCallout)
                        .foregroundColor(.bcSecondary)
                }
            }
        }
    }
}

struct BCStatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.bcCaptionBold)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(8)
    }
}

struct BCEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.bcTextLight)
            Text(title)
                .font(.bcTitle3)
                .foregroundColor(.bcText)
            Text(subtitle)
                .font(.bcBody)
                .foregroundColor(.bcTextSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle = actionTitle, let action = action {
                BCPrimaryButton(title: actionTitle, action: action)
                    .frame(width: 200)
            }
        }
        .padding(32)
    }
}
