# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-08-29

### Added

- `PhoenixPaper.Flash` (`pp_flash_group/1` / `pp_flash/1`) — renders
  Phoenix's `@flash` as stacked `PhoenixPaper.Snackbar`s, with dismissal
  wired to LiveView's built-in `lv:clear-flash` (no LiveView handler
  needed) and opt-in `auto_hide_duration`.
- `pp_button/1` link mode: passing `href`, `navigate` or `patch` renders a
  `Phoenix.Component.link/1` (`<a>`) instead of a `<button>`, keeping every
  variant/color/ripple. Avoids nesting a `<button>` inside an `<a>` for
  navigation.
- `pp_app_bar/1` gains `max_width` (cap and centre the toolbar content,
  like wrapping MUI's `Toolbar` in a `Container`) and `disable_gutters`
  (MUI's `Toolbar disableGutters`).
- `pp_input/1` and `pp_select/1` gain `hide_label` — a dense, unwrapped
  variant (no wrapper column, no floating label, no notch, no helper/error
  rows) for inline use in a filter toolbar. MUI's `hiddenLabel` idea.
- `pp_snackbar/1` gains `on_close` (a trailing ✕ button, MUI's
  close-IconButton pattern), `auto_hide_duration` (hook-free client-side
  auto-dismiss), and `positioned` (drop the viewport anchoring to place
  the chip inside your own container).

### Changed

- `pp_app_bar/1`'s default toolbar gutters are now responsive (`px-4`
  rising to `px-6` at the `sm` breakpoint), matching MUI's `Toolbar`.

## [0.1.0] - 2026-08-28

### Added

- Initial release: a Material Design component library for Phoenix and
  LiveView, styled with Tailwind CSS.

[Unreleased]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/z7ealth/phoenix_paper/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/z7ealth/phoenix_paper/releases/tag/v0.1.0
