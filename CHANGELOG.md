# Changelog

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
