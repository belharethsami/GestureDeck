import Foundation
import GestureDeckCore

@MainActor
private final class TestRunner {
    private var failures = 0

    func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard condition() else {
            failures += 1
            FileHandle.standardError.write(Data("FAIL: \(message) [\(file):\(line)]\n".utf8))
            return
        }
    }

    func finish() -> Never {
        if failures > 0 {
            FileHandle.standardError.write(Data("\(failures) logic test(s) failed.\n".utf8))
            exit(1)
        }
        print("All GestureDeck logic tests passed.")
        exit(0)
    }
}

@main
enum GestureDeckLogicTests {
    @MainActor
    static func main() {
        let runner = TestRunner()
        testThreeFingerRightSwipe(runner)
        testFiveFingerUpSwipe(runner)
        testShortAndDiagonalMovements(runner)
        testFingerCountTransitions(runner)
        testConsecutiveSameDirectionSwipesAfterPartialLift(runner)
        testConfigurationRoundTrip(runner)
        testLaunchAtLoginStates(runner)
        runner.finish()
    }

    @MainActor
    private static func testThreeFingerRightSwipe(_ runner: TestRunner) {
        var recognizer = SwipeRecognizer()
        runner.expect(recognizer.consume(touches: points(count: 3, offsetX: 0), timestamp: 0) == nil, "Swipe should begin silently")
        runner.expect(recognizer.consume(touches: points(count: 3, offsetX: 0.08), timestamp: 0.2) == nil, "Swipe should accumulate")
        runner.expect(recognizer.consume(touches: points(count: 3, offsetX: 0.18), timestamp: 0.4) == nil, "Swipe should accumulate")
        let result = recognizer.consume(touches: [], timestamp: 0.5)
        runner.expect(result?.fingerCount == 3, "Three-finger swipe should retain its count")
        runner.expect(result?.direction == .right, "Positive x movement should be right")
    }

    @MainActor
    private static func testFiveFingerUpSwipe(_ runner: TestRunner) {
        var recognizer = SwipeRecognizer()
        _ = recognizer.consume(touches: points(count: 5, offsetY: 0), timestamp: 10)
        _ = recognizer.consume(touches: points(count: 5, offsetY: 0.15), timestamp: 10.3)
        let result = recognizer.consume(touches: [], timestamp: 10.5)
        runner.expect(result?.fingerCount == 5, "Five-finger swipe should retain its count")
        runner.expect(result?.direction == .up, "Positive y movement should be up")
    }

    @MainActor
    private static func testShortAndDiagonalMovements(_ runner: TestRunner) {
        var shortRecognizer = SwipeRecognizer()
        _ = shortRecognizer.consume(touches: points(count: 4), timestamp: 0)
        _ = shortRecognizer.consume(touches: points(count: 4, offsetX: 0.05), timestamp: 0.2)
        runner.expect(shortRecognizer.consume(touches: [], timestamp: 0.3) == nil, "Short movement must not fire")

        var diagonalRecognizer = SwipeRecognizer()
        _ = diagonalRecognizer.consume(touches: points(count: 4), timestamp: 0)
        _ = diagonalRecognizer.consume(touches: points(count: 4, offsetX: 0.2, offsetY: 0.2), timestamp: 0.3)
        runner.expect(diagonalRecognizer.consume(touches: [], timestamp: 0.4) == nil, "Ambiguous diagonal movement must not fire")
    }

    @MainActor
    private static func testFingerCountTransitions(_ runner: TestRunner) {
        var recognizer = SwipeRecognizer()
        _ = recognizer.consume(touches: points(count: 3), timestamp: 0)
        _ = recognizer.consume(touches: points(count: 4, offsetX: 0.05), timestamp: 0.1)
        _ = recognizer.consume(touches: points(count: 4, offsetX: 0.22), timestamp: 0.3)
        let result = recognizer.consume(touches: [], timestamp: 0.4)
        runner.expect(result?.fingerCount == 4, "Maximum stable finger count should select the binding")
        runner.expect(result?.direction == .right, "Movement after adding a finger should still recognize")
    }

    @MainActor
    private static func testConsecutiveSameDirectionSwipesAfterPartialLift(_ runner: TestRunner) {
        var recognizer = SwipeRecognizer()

        _ = recognizer.consume(touches: points(count: 3), timestamp: 0)
        _ = recognizer.consume(touches: points(count: 3, offsetX: 0.18), timestamp: 0.2)
        let first = recognizer.consume(
            touches: points(count: 2, offsetX: 0.18),
            timestamp: 0.3
        )

        _ = recognizer.consume(touches: points(count: 3), timestamp: 0.4)
        _ = recognizer.consume(touches: points(count: 3, offsetX: 0.18), timestamp: 0.6)
        let second = recognizer.consume(
            touches: points(count: 2, offsetX: 0.18),
            timestamp: 0.7
        )

        runner.expect(first?.direction == .right, "A swipe should complete when fewer than three contacts remain")
        runner.expect(second?.direction == .right, "A same-direction swipe should rearm after the preceding lift")
    }

    @MainActor
    private static func testConfigurationRoundTrip(_ runner: TestRunner) {
        let target = ApplicationTarget(name: "Notes", path: "/System/Applications/Notes.app", bundleIdentifier: "com.apple.Notes")
        let original = GestureDeckConfiguration(
            gestures: [.init(fingerCount: 4, direction: .left, application: target)],
            shortcuts: [.init(application: target)]
        )
        let encoded = try! JSONEncoder().encode(original)
        let decoded = try! JSONDecoder().decode(GestureDeckConfiguration.self, from: encoded)
        runner.expect(decoded == original, "Configuration must round-trip through JSON")
    }

    @MainActor
    private static func testLaunchAtLoginStates(_ runner: TestRunner) {
        runner.expect(!LaunchAtLoginState.disabled.isRequested, "Disabled login items must appear off")
        runner.expect(LaunchAtLoginState.enabled.isRequested, "Enabled login items must appear on")
        runner.expect(LaunchAtLoginState.enabled.isEffective, "Enabled login items must be effective")
        runner.expect(
            LaunchAtLoginState.requiresApproval.isRequested,
            "Registered login items awaiting approval must remain requested"
        )
        runner.expect(
            !LaunchAtLoginState.requiresApproval.isEffective,
            "Login items awaiting approval must not be reported as effective"
        )
        runner.expect(!LaunchAtLoginState.unavailable.isRequested, "Unavailable login items must appear off")
        runner.expect(
            LaunchAtLoginState.disabled.action(toSetRequested: true) == .register,
            "Turning on a disabled login item must register it"
        )
        runner.expect(
            LaunchAtLoginState.enabled.action(toSetRequested: false) == .unregister,
            "Turning off an enabled login item must unregister it"
        )
        runner.expect(
            LaunchAtLoginState.requiresApproval.action(toSetRequested: false) == .unregister,
            "Turning off an item awaiting approval must unregister it"
        )
        runner.expect(
            LaunchAtLoginState.unavailable.action(toSetRequested: true) == .register,
            "Unavailable login items must attempt first-time registration"
        )
    }

    private static func points(
        count: Int,
        offsetX: Float = 0,
        offsetY: Float = 0
    ) -> [TouchPoint] {
        (0..<count).map { index in
            TouchPoint(
                id: Int32(index),
                x: 0.2 + Float(index) * 0.08 + offsetX,
                y: 0.4 + offsetY
            )
        }
    }
}
