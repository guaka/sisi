import XCTest

final class UsageLimiterTests: XCTestCase {

    private var defaults: UserDefaults!
    private var sut: UsageLimiter!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "UsageLimiterTests-\(UUID().uuidString)")
        sut = UsageLimiter(userDefaults: defaults)
        sut.nudgeThreshold = 25
        sut.lockThreshold = 30
        sut.snoozeDuration = 5
        sut.maxSnoozesPerDay = 2
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: defaults.dictionaryRepresentation().keys.first ?? "")
        sut = nil
        defaults = nil
        super.tearDown()
    }

    func testNudgeAndLockThresholds() {
        let day = dayStamp()
        defaults.set(day, forKey: UsageLimiter.dayKey)
        defaults.set(26.0, forKey: UsageLimiter.secondsKey)
        sut = UsageLimiter(userDefaults: defaults)
        sut.nudgeThreshold = 25
        sut.lockThreshold = 30
        XCTAssertTrue(sut.shouldShowNudge)
        XCTAssertFalse(sut.isLocked)

        defaults.set(31.0, forKey: UsageLimiter.secondsKey)
        sut = UsageLimiter(userDefaults: defaults)
        sut.nudgeThreshold = 25
        sut.lockThreshold = 30
        XCTAssertTrue(sut.isLocked)
        XCTAssertFalse(sut.shouldShowNudge)
    }

    func testSnoozeTemporarilyUnlocks() {
        defaults.set(dayStamp(), forKey: UsageLimiter.dayKey)
        defaults.set(31.0, forKey: UsageLimiter.secondsKey)
        sut = UsageLimiter(userDefaults: defaults)
        sut.nudgeThreshold = 25
        sut.lockThreshold = 30
        sut.snoozeDuration = 60
        XCTAssertTrue(sut.isLocked)
        XCTAssertTrue(sut.canSnooze)

        sut.snooze()
        XCTAssertFalse(sut.isLocked)
        XCTAssertEqual(sut.snoozeCountToday, 1)

        sut.snooze()
        XCTAssertEqual(sut.snoozeCountToday, 2)
        XCTAssertFalse(sut.canSnooze)
    }

    func testDisabledNeverLocks() {
        defaults.set(dayStamp(), forKey: UsageLimiter.dayKey)
        defaults.set(999.0, forKey: UsageLimiter.secondsKey)
        sut = UsageLimiter(userDefaults: defaults)
        sut.isEnabled = false
        XCTAssertFalse(sut.isLocked)
        XCTAssertFalse(sut.shouldShowNudge)
    }

    private func dayStamp() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return "\(components.year!)-\(components.month!)-\(components.day!)"
    }
}
