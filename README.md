# GestureDeck

GestureDeck is a focused, open-source macOS automation utility. It maps global
3-, 4-, and 5-finger directional trackpad swipes—or user-recorded global
keyboard shortcuts—to launching an application.

It is intentionally smaller than BetterTouchTool. GestureDeck does not copy its
branding or code and is not affiliated with its developer.

## Features

- 3-, 4-, and 5-finger swipes in four directions
- Multiple configurable gesture-to-application bindings
- User-recorded global keyboard shortcuts
- Application picker and one-click test launch
- Local JSON configuration in `UserDefaults`
- Live finger-count and last-recognized-gesture diagnostics
- Menu-bar enable/pause control
- No account, network client, analytics, or typed-text recording

## Important platform limitation

Apple's public AppKit gesture recognizers work inside an application's views;
they do not provide arbitrary global 3/4/5-finger contact streams. GestureDeck
therefore uses `OpenMultitouchSupport`, which wraps Apple's private
`MultitouchSupport.framework`.

Consequences:

- macOS 15 or newer is required.
- The App Sandbox must be disabled.
- GestureDeck is not suitable for Mac App Store distribution.
- A macOS update may require changes to the trackpad layer.
- GestureDeck observes gestures but does not suppress macOS's own gestures.
  Disable conflicting gestures in System Settings when necessary.

Keyboard shortcuts use the macOS Carbon hot-key service. GestureDeck registers
only the combinations you configure; it does not install a key logger or retain
ordinary keystrokes.

## Build

Requirements:

- macOS 15+
- Xcode 26.2+ or matching Command Line Tools
- Swift 6.2+

```sh
make test
make build
make app
```

`make app` creates a Universal 2 bundle at `dist/GestureDeck.app`. Create a
drag-to-Applications disk image with:

```sh
make dmg
```

The local script applies an ad-hoc signature. Public distribution should use an
Apple Developer ID Application certificate and Apple's notarization service.
Do not disable Gatekeeper, SIP, or device-management controls.

## Gesture recognition

GestureDeck calculates the contact centroid and accumulates movement only while
the finger count is stable. It recognizes a gesture when all contacts lift if:

- the maximum contact count is exactly 3, 4, or 5;
- travel exceeds the configured internal threshold;
- one axis clearly dominates the other; and
- the gesture completes within 1.5 seconds.

This rejects short movements, ambiguous diagonal motions, and centroid jumps
caused by adding or removing a finger.

## Test

```sh
make test
```

The deterministic logic harness covers each supported finger count, all core
recognition rules, contact-count transitions, and configuration persistence.
Real trackpad hardware must still be exercised manually because synthetic input
cannot reproduce Apple's private raw-contact callback.

## License

MIT. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for dependencies.
