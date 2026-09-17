import Foundation
import Observation
import Dependencies

/// Tracks foreground app usage and enforces a soft daily limit (nudge at 25m, lock at 30m).
@Observable final class UsageLimiter {
    static let enabledKey = "com.verse.nos.usageLimiter.enabled"
    static let secondsKey = "com.verse.nos.usageLimiter.seconds"
    static let dayKey = "com.verse.nos.usageLimiter.day"
    static let snoozeCountKey = "com.verse.nos.usageLimiter.snoozeCount"
    static let snoozeUntilKey = "com.verse.nos.usageLimiter.snoozeUntil"

    /// Foreground seconds before a non-blocking nudge.
    var nudgeThreshold: TimeInterval = 25 * 60
    /// Foreground seconds before the blocking overlay.
    var lockThreshold: TimeInterval = 30 * 60
    /// Extra time granted per snooze.
    var snoozeDuration: TimeInterval = 5 * 60
    /// Maximum snoozes per local calendar day.
    var maxSnoozesPerDay = 2

    private(set) var elapsedToday: TimeInterval = 0
    private(set) var snoozeCountToday = 0
    private(set) var snoozeUntil: Date?
    /// Live elapsed including the current foreground session; updated by ``tick()``.
    private(set) var liveElapsedToday: TimeInterval = 0
    var isEnabled: Bool {
        didSet { userDefaults.set(isEnabled, forKey: Self.enabledKey) }
    }

    private var sessionStartedAt: Date?
    private let calendar = Calendar.current
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.isEnabled = userDefaults.object(forKey: Self.enabledKey) as? Bool ?? true
        reloadFromDefaults()
    }

    var shouldShowNudge: Bool {
        guard isEnabled else { return false }
        guard !isLocked else { return false }
        return liveElapsedToday >= nudgeThreshold && liveElapsedToday < lockThreshold
    }

    var isLocked: Bool {
        guard isEnabled else { return false }
        if let snoozeUntil, snoozeUntil > Date() {
            return false
        }
        return liveElapsedToday >= lockThreshold
    }

    var canSnooze: Bool {
        snoozeCountToday < maxSnoozesPerDay
    }

    var lockMessage: String {
        if snoozeCountToday == 0 {
            return "You've been scrolling for about 30 minutes. Time to stop."
        }
        return "Really — put the phone down. Come back tomorrow."
    }

    /// Call when the scene becomes active.
    func appDidBecomeActive() {
        rolloverIfNeeded()
        sessionStartedAt = Date()
        liveElapsedToday = effectiveElapsed
    }

    /// Call when the scene becomes inactive / background.
    func appWillResignActive() {
        commitSession()
        sessionStartedAt = nil
        liveElapsedToday = elapsedToday
    }

    /// Tick while foregrounded (e.g. every few seconds from the UI).
    func tick() {
        guard sessionStartedAt != nil else {
            liveElapsedToday = elapsedToday
            return
        }
        rolloverIfNeeded()
        liveElapsedToday = effectiveElapsed
    }

    func snooze() {
        guard canSnooze else { return }
        commitSession()
        snoozeCountToday += 1
        snoozeUntil = Date().addingTimeInterval(snoozeDuration)
        persist()
        sessionStartedAt = Date()
    }

    // MARK: - Private

    private var effectiveElapsed: TimeInterval {
        var total = elapsedToday
        if let sessionStartedAt {
            total += Date().timeIntervalSince(sessionStartedAt)
        }
        return total
    }

    private func commitSession() {
        guard let sessionStartedAt else { return }
        elapsedToday += Date().timeIntervalSince(sessionStartedAt)
        self.sessionStartedAt = Date()
        persist()
    }

    private func rolloverIfNeeded() {
        let today = dayString(for: Date())
        let storedDay = userDefaults.string(forKey: Self.dayKey)
        if let storedDay, storedDay != today {
            elapsedToday = 0
            snoozeCountToday = 0
            snoozeUntil = nil
            userDefaults.set(today, forKey: Self.dayKey)
            persist()
        } else if storedDay == nil {
            userDefaults.set(today, forKey: Self.dayKey)
        }
    }

    private func reloadFromDefaults() {
        rolloverIfNeeded()
        elapsedToday = userDefaults.double(forKey: Self.secondsKey)
        snoozeCountToday = userDefaults.integer(forKey: Self.snoozeCountKey)
        if let until = userDefaults.object(forKey: Self.snoozeUntilKey) as? Date {
            snoozeUntil = until
        }
        liveElapsedToday = elapsedToday
    }

    private func persist() {
        userDefaults.set(elapsedToday, forKey: Self.secondsKey)
        userDefaults.set(snoozeCountToday, forKey: Self.snoozeCountKey)
        userDefaults.set(snoozeUntil, forKey: Self.snoozeUntilKey)
        userDefaults.set(dayString(for: Date()), forKey: Self.dayKey)
    }

    private func dayString(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year!)-\(components.month!)-\(components.day!)"
    }
}

private enum UsageLimiterKey: DependencyKey {
    static let liveValue = UsageLimiter()
    static let testValue = UsageLimiter(userDefaults: UserDefaults())
    static let previewValue = UsageLimiter(userDefaults: UserDefaults())
}

extension DependencyValues {
    var usageLimiter: UsageLimiter {
        get { self[UsageLimiterKey.self] }
        set { self[UsageLimiterKey.self] = newValue }
    }
}
