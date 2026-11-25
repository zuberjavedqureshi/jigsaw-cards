# puzzle_domain (S-01 spike placeholder)

Throwaway placeholder used by the S-01 Hybrid Shell spike to prove the
pure-Dart domain boundary. It contains only `GridSize` / `GridCell`.

Rules: no Flutter, no Flame, no `dart:ui`. Tests run on the plain Dart VM:

```sh
dart test
```

The boundary is checked by `../../tool/check_domain_boundary.sh`.
