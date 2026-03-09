import SwiftUI

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - AppTheme

enum AppTheme {

    // MARK: - Colors (Nocturnal Cryo-Lab Palette)

    enum Colors {
        // Backgrounds
        static let background        = Color(hex: "0D0B12")   // deepest bg
        static let groupedBackground = Color(hex: "0D0B12")
        static let secondaryBackground = Color(hex: "1A1625") // card bg
        static let tertiaryBackground  = Color(hex: "221B2E") // row / column header bg
        static let separator           = Color(hex: "2E2540")

        // Text
        static let primary   = Color(hex: "e5eaf5")   // Freeze Purple
        static let secondary = Color(hex: "a28089")   // Heavy Purple

        // Cryo palette (named)
        static let iceCold      = Color(hex: "a0d2eb") // Ice Cold
        static let mediumPurple = Color(hex: "d0bdf4") // Medium Purple
        static let purplePain   = Color(hex: "8458B3") // Purple Pain
        static let heavyPurple  = Color(hex: "a28089") // Heavy Purple

        // Semantic
        static let accent          = Color(hex: "8458B3") // Purple Pain
        static let completedSet    = Color(hex: "8458B3") // Purple Pain
        static let restTimerActive = Color(hex: "a0d2eb") // Ice Cold
        static let prBadge         = Color(hex: "FFD700") // Gold
        static let destructive     = Color.red
        static let success         = Color.green
        static let warning         = Color.orange

        // Set type badge colors
        static let warmupBadge   = Color(hex: "a0d2eb") // Ice Cold
        static let dropSetBadge  = Color(hex: "d0bdf4") // Medium Purple
        static let failureBadge  = Color(hex: "8458B3") // Purple Pain

        // Legacy aliases (kept for compatibility)
        static let pendingSet = Color(hex: "221B2E")
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle  = Font.largeTitle.weight(.bold)
        static let title       = Font.title.weight(.semibold)
        static let title2      = Font.title2.weight(.semibold)
        static let title3      = Font.title3.weight(.medium)
        static let headline    = Font.headline
        static let body        = Font.body
        static let callout     = Font.callout
        static let subheadline = Font.subheadline
        static let footnote    = Font.footnote
        static let caption     = Font.caption
        static let caption2    = Font.caption2

        static let timer          = Font.system(size: 48, weight: .thin, design: .monospaced)
        static let timerSmall     = Font.system(size: 32, weight: .light, design: .monospaced)
        static let timerMini      = Font.system(size: 20, weight: .regular, design: .monospaced)
        static let timerCountdown = Font.system(size: 72, weight: .bold, design: .rounded)
        static let setNumber      = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let weightInput    = Font.system(size: 17, weight: .medium, design: .rounded)
        static let columnHeader   = Font.system(size: 11, weight: .heavy, design: .default)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxSmall: CGFloat = 2
        static let xSmall: CGFloat  = 4
        static let small: CGFloat   = 8
        static let medium: CGFloat  = 12
        static let regular: CGFloat = 16
        static let large: CGFloat   = 20
        static let xLarge: CGFloat  = 24
        static let xxLarge: CGFloat = 32
        static let xxxLarge: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat  = 6
        static let medium: CGFloat = 10
        static let large: CGFloat  = 14
        static let xLarge: CGFloat = 20
    }

    // MARK: - Animation

    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let spring   = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let quick    = SwiftUI.Animation.easeOut(duration: 0.15)
    }
}

// MARK: - View Modifiers

extension View {
    func cardStyle() -> some View {
        self
            .background(AppTheme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
    }

    func sectionHeaderStyle() -> some View {
        self
            .font(AppTheme.Typography.footnote)
            .foregroundStyle(AppTheme.Colors.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// MARK: - Duration Formatting

extension TimeInterval {
    var workoutDurationFormatted: String {
        let totalSeconds = Int(self)
        let hours   = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var restTimerFormatted: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var shortDurationFormatted: String {
        let totalSeconds = Int(self)
        let hours   = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }
}

extension Int {
    var workoutTimerFormatted: String {
        let hours   = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var restTimerFormatted: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension Double {
    func weightFormatted(unit: WeightUnit) -> String {
        if self == self.rounded() {
            return String(format: "%.0f %@", self, unit.label)
        } else {
            return String(format: "%.1f %@", self, unit.label)
        }
    }

    var oneRMFormatted: String {
        String(format: "%.1f", self)
    }
}
