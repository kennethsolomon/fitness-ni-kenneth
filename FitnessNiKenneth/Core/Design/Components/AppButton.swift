import SwiftUI

// MARK: - AppButton

struct AppButton: View {
    enum Style {
        case primary, secondary, destructive, ghost
    }

    let title: String
    let style: Style
    let action: () -> Void

    init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.medium)
                .foregroundStyle(foregroundColor)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: AppTheme.Colors.accent
        case .secondary: AppTheme.Colors.secondaryBackground
        case .destructive: AppTheme.Colors.destructive
        case .ghost: .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: .white
        case .secondary: AppTheme.Colors.primary
        case .destructive: .white
        case .ghost: AppTheme.Colors.accent
        }
    }
}

// MARK: - IconButton

struct IconButton: View {
    let systemName: String
    let label: String?
    let action: () -> Void

    init(_ systemName: String, label: String? = nil, action: @escaping () -> Void) {
        self.systemName = systemName
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            if let label {
                Label(label, systemImage: systemName)
                    .font(AppTheme.Typography.subheadline)
            } else {
                Image(systemName: systemName)
                    .font(AppTheme.Typography.body)
            }
        }
    }
}

// MARK: - CompletionCheckmark

struct CompletionCheckmark: View {
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isCompleted ? AppTheme.Colors.completedSet : AppTheme.Colors.pendingSet)
                    .frame(width: 36, height: 36)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(AppTheme.Animation.spring, value: isCompleted)
    }
}

// MARK: - PRBadge

struct PRBadge: View {
    var body: some View {
        Text("PR")
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppTheme.Colors.prBadge)
            .clipShape(Capsule())
    }
}
