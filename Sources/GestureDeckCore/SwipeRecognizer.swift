import Foundation

public struct TouchPoint: Equatable, Sendable {
    public var id: Int32
    public var x: Float
    public var y: Float

    public init(id: Int32, x: Float, y: Float) {
        self.id = id
        self.x = x
        self.y = y
    }
}

public struct RecognizedSwipe: Equatable, Sendable {
    public var fingerCount: Int
    public var direction: SwipeDirection
    public var distance: Float
    public var duration: TimeInterval

    public init(
        fingerCount: Int,
        direction: SwipeDirection,
        distance: Float,
        duration: TimeInterval
    ) {
        self.fingerCount = fingerCount
        self.direction = direction
        self.distance = distance
        self.duration = duration
    }
}

/// Converts raw contact frames into a single directional swipe.
///
/// Centroid movement is accumulated only while the contact count is stable.
/// This prevents adding or removing a finger from looking like a sudden swipe.
public struct SwipeRecognizer: Sendable {
    public var minimumDistance: Float
    public var axisDominance: Float
    public var maximumDuration: TimeInterval

    private var startedAt: TimeInterval?
    private var maximumFingerCount = 0
    private var lastCentroid: (x: Float, y: Float)?
    private var lastCount = 0
    private var accumulatedX: Float = 0
    private var accumulatedY: Float = 0

    public init(
        minimumDistance: Float = 0.12,
        axisDominance: Float = 1.25,
        maximumDuration: TimeInterval = 1.5
    ) {
        self.minimumDistance = minimumDistance
        self.axisDominance = axisDominance
        self.maximumDuration = maximumDuration
    }

    public mutating func consume(
        touches: [TouchPoint],
        timestamp: TimeInterval
    ) -> RecognizedSwipe? {
        let activeTouches = touches
        let count = activeTouches.count

        if count == 0 {
            return finish(at: timestamp)
        }

        guard (3...5).contains(count) else {
            if startedAt != nil {
                maximumFingerCount = max(maximumFingerCount, count)
            }
            lastCentroid = centroid(of: activeTouches)
            lastCount = count
            return nil
        }

        if startedAt == nil {
            startedAt = timestamp
        }

        maximumFingerCount = max(maximumFingerCount, count)
        let currentCentroid = centroid(of: activeTouches)

        if let lastCentroid, lastCount == count {
            accumulatedX += currentCentroid.x - lastCentroid.x
            accumulatedY += currentCentroid.y - lastCentroid.y
        }

        lastCentroid = currentCentroid
        lastCount = count
        return nil
    }

    public mutating func reset() {
        startedAt = nil
        maximumFingerCount = 0
        lastCentroid = nil
        lastCount = 0
        accumulatedX = 0
        accumulatedY = 0
    }

    private mutating func finish(at timestamp: TimeInterval) -> RecognizedSwipe? {
        guard let startedAt else {
            reset()
            return nil
        }

        let duration = max(0, timestamp - startedAt)
        let horizontal = abs(accumulatedX)
        let vertical = abs(accumulatedY)
        let distance = max(horizontal, vertical)

        defer { reset() }

        guard
            (3...5).contains(maximumFingerCount),
            duration <= maximumDuration,
            distance >= minimumDistance
        else {
            return nil
        }

        let direction: SwipeDirection
        if horizontal >= vertical * axisDominance {
            direction = accumulatedX >= 0 ? .right : .left
        } else if vertical >= horizontal * axisDominance {
            direction = accumulatedY >= 0 ? .up : .down
        } else {
            return nil
        }

        return RecognizedSwipe(
            fingerCount: maximumFingerCount,
            direction: direction,
            distance: distance,
            duration: duration
        )
    }

    private func centroid(of touches: [TouchPoint]) -> (x: Float, y: Float) {
        let sum = touches.reduce(into: (x: Float(0), y: Float(0))) { partial, touch in
            partial.x += touch.x
            partial.y += touch.y
        }
        let divisor = Float(max(1, touches.count))
        return (sum.x / divisor, sum.y / divisor)
    }
}
