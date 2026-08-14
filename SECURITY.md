# Security

GestureDeck has no network client, updater, analytics, shell execution, or
privileged helper. It launches only application bundle paths explicitly chosen
by the user.

Global shortcuts are registered with the macOS hot-key service. GestureDeck does
not monitor ordinary typed text. Global trackpad contacts come from Apple's
private `MultitouchSupport.framework` through the open-source
OpenMultitouchSupport package; the application is deliberately unsandboxed
because this framework does not function in the App Sandbox.

Please report vulnerabilities privately to the repository owner before opening
a public issue. Include the GestureDeck and macOS versions, reproduction steps,
and expected impact.
