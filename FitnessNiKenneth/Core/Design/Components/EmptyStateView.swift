import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(AppTheme.Colors.secondary)

            VStack(spacing: AppTheme.Spacing.small) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xxLarge)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding(AppTheme.Spacing.xxLarge)
    }
}

// MARK: - StatCell

struct StatCell: View {
    let label: String
    let value: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondary)
                .textCase(.uppercase)
                .tracking(0.3)

            Text(value)
                .font(AppTheme.Typography.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.Colors.primary)

            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.Typography.caption2)
                    .foregroundStyle(AppTheme.Colors.secondary)
            }
        }
    }
}

// MARK: - MuscleGroupTag

struct MuscleGroupTag: View {
    let muscle: MuscleGroup
    var isPrimary: Bool = true

    var body: some View {
        Text(muscle.displayName)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isPrimary ? AppTheme.Colors.accent.opacity(0.15) : AppTheme.Colors.secondaryBackground)
            .foregroundStyle(isPrimary ? AppTheme.Colors.accent : AppTheme.Colors.secondary)
            .clipShape(Capsule())
    }
}
