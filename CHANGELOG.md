# Changelog

## [Unreleased]

### Fixed

- **`Glyphs/IconResolution` no longer fails open on a missing icon directory.**
  A directory that did not exist produced the same empty list as one that
  existed with no SVGs, and both were read as "nothing to check" — so a library
  that was never synced, or a `DefaultVariant` naming a variant the project does
  not have, silently disabled the cop for every call site of that library. Green
  cop, green CI, no validation at all, indefinitely. `load_icons` now returns
  `nil` for an absent directory and `[]` for an empty one; the absent case warns
  once per library/variant, naming the path. The synced-but-empty case still
  passes silently. Refs #8

- **Cop options are declared, so RuboCop stops calling them unsupported.**
  `config/default.yml` documented `Libraries` (`Glyphs/IconResolution`) and
  `Mappings` (`Glyphs/LegacyIconHelper`) only in comments, and never mentioned
  `LibraryComponents` (`Glyphs/LegacyIconHelper`, `Glyphs/PreferLibraryComponent`)
  at all. RuboCop derives its supported-parameter list from the keys actually
  present in that file, so it warned `does not support <param> parameter` on
  every run — for four working options, one of which
  `Glyphs/LegacyIconHelper` itself tells you to add. Each is now declared with an
  empty default (a no-op merge), so the options are validated instead of
  reported, with behaviour unchanged. Refs #7

- **Declaration harvest unwraps trailing `.freeze`.** `ICONS = { "x" => :car }.freeze`
  (and `%i[a b].freeze`) used to yield a Prism `CallNode`, so hash/array values
  were never collected. Cross-file dynamics (`PhosphorIcon(@icon)` in a shared
  component + names only in a frozen `ICONS` map) then lost those icons at
  `glyphs:prune_icons`. `collect_declaration` now unwraps zero-arg `.freeze`
  (and parentheses) before walking the value.

### Added

- **`Glyphs/IconResolution` gained a `Strict` option** (default `false`). It
  escalates the missing-icon-directory warning above to an offence, so projects
  that depend on this cop can fail closed in CI instead of trusting a warning
  not to scroll past.

- **Dynamic icon calls are now resolved from source.** `SourceScanner` no longer
  silently skips `LucideIcon(some_var)` / `PhosphorIcon(tile[:icon])` — it harvests
  the literal name from two places so the pruner keeps it:
  - _file-scoped_: a file that dynamically renders a library keeps every
    icon-name-shaped literal in that file for that library (ternaries, `case`,
    locals);
  - _declaration-based_: literals in icon-declaration positions anywhere (a hash
    pair keyed `/icon/i`, or a constant named `/ICON/`) are kept for every
    dynamically-rendered library, closing the cross-file gap (e.g. a notifier
    `ICON = :bell` constant rendered from a view). Frozen maps
    (`ICONS = { … }.freeze`) are included — see Fixed above.

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
