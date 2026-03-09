import SwiftUI

// MARK: - AppTheme

enum AppTheme {

    // MARK: - Colors

    enum Colors {
        static let accent = Color.accentColor
        static let primary = Color.primary
        static let secondary = Color.secondary

        static let background = Color(.systemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)

        static let separator = Color(.separator)
        static let success = Color.green
        static let warning = Color.orange
        static let destructive = Color.red

        static let completedSet = Color.green
        static let pendingSet = Color(.secondarySystemBackground)
        static let restTimerActive = Color.orange
        static let prBadge = Color.yellow
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2

        static let timer = Font.system(size: 48, weight: .thin, design: .monospaced)
        static let timerSmall = Font.system(size: 32, weight: .light, design: .monospaced)
        static let timerMini = Font.system(size: 20, weight: .regular, design: .monospaced)
        static let setNumber = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let weightInput = Font.system(size: 17, weight: .medium, design: .rounded)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxSmall: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let regular: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
        static let xxxLarge: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
        static let xLarge: CGFloat = 20
    }

    // MARK: - Animation

    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
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
        let hours = totalSeconds / 3600
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
        let hours = totalSeconds / 3600
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
        let hours = self / 3600
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
