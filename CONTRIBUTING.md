# Contributing

Contributions are welcome. Keep the raw trackpad adapter isolated from gesture
recognition, persistence, and actions so a future public API or replacement
implementation can be adopted without rewriting the app.

Before opening a pull request, run:

```sh
make test
make build
```

Changes to gesture recognition must include deterministic cases in
`Tests/GestureDeckLogicTests`. Do not add network access, shell execution,
privileged helpers, or additional action types without documenting the new
security boundary.
