import SwiftUI
import Dependencies

/// Non-blocking banner shown around the 25-minute mark.
struct UsageNudgeBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "hourglass")
                .foregroundStyle(Color.primaryTxt)
            Text("You've been here about 25 minutes. Consider wrapping up.")
                .font(.clarity(.medium, textStyle: .subheadline))
                .foregroundStyle(Color.primaryTxt)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient.horizontalAccentReversed)
        )
        .padding(.horizontal, 12)
    }
}

/// Full-screen lock after ~30 minutes of foreground use.
struct UsageLockOverlay: View {
    @Dependency(\.usageLimiter) private var usageLimiter

    var body: some View {
        ZStack {
            Color.actionSheetOverlay.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.primaryTxt)

                Text(usageLimiter.lockMessage)
                    .font(.clarity(.bold, textStyle: .title3))
                    .foregroundStyle(Color.primaryTxt)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("Come back tomorrow — or snooze for five minutes.")
                    .font(.clarity(.regular, textStyle: .footnote))
                    .foregroundStyle(Color.secondaryTxt)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if usageLimiter.canSnooze {
                    ActionButton(title: "Snooze 5 minutes") {
                        usageLimiter.snooze()
                    }
                    .padding(.horizontal, 40)
                } else {
                    Text("No more snoozes today.")
                        .font(.clarity(.medium, textStyle: .subheadline))
                        .foregroundStyle(Color.secondaryTxt)
                }
            }
            .padding(24)
        }
        .accessibilityAddTraits(.isModal)
    }
}
