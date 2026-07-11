# Changelog

## [Unreleased]

### Added

- **Dynamic icon calls are now resolved from source.** `SourceScanner` no longer
  silently skips `LucideIcon(some_var)` / `PhosphorIcon(tile[:icon])` — it harvests
  the literal name from two places so the pruner keeps it:
  - _file-scoped_: a file that dynamically renders a library keeps every
    icon-name-shaped literal in that file for that library (ternaries, `case`,
    locals);
  - _declaration-based_: literals in icon-declaration positions anywhere (a hash
    pair keyed `/icon/i`, or a constant named `/ICON/`) are kept for every
    dynamically-rendered library, closing the cross-file gap (e.g. a notifier
    `ICON = :bell` constant rendered from a view).

  This makes `keep_icons` a last-resort escape hatch (DB/ENV/gem-chrome names)
  rather than the primary mechanism. Only literals are harvested, so the scanner
  never invents a reference.

## [0.2.0] - 2026-07-07

### Changed

- **Breaking:** `config.raise_on_missing_icon` (a callable) is now `config.raise_on_missing`,
  an honest boolean. The default is evaluated once: `Rails.env.local?` under Rails, `true` outside.
- **Breaking:** `config.on_missing_icon` now defaults to `nil` — set it only if you want a handler.

### Added

- Release workflow with RubyGems trusted publishing (OIDC) and Sigstore attestation.

## [0.1.0] - 2026-07-07

### Added

- `Glyphs::Icon` base Phlex component rendering SVGs through the `icons` gem (rails_icons).
- Library components exposed via `Phlex::Kit`: `LucideIcon`, `PhosphorIcon`, `HeroIcon`, `TablerIcon`,
  `FeatherIcon`, `BoxIcon`, `FlagIcon`, `HugeIcon`, `LinearIcon`, `RadixIcon`, `SidekickIcon`,
  `WeatherIcon`, `AnimatedIcon`.
- `Glyphs.register_library` for custom icon libraries.
- Configurable missing-icon policy (`raise_on_missing_icon`, `on_missing_icon` hook, `fallback_icons`)
  and per-process SVG render cache (`cache_svgs`).
- RuboCop plugin (lint_roller) with `Glyphs/LegacyIconHelper`, `Glyphs/IconResolution`, and
  `Glyphs/PreferLibraryComponent`.
