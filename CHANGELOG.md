# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.5] - 2026-09-25

### Added

- `pp_accordion/1` gains `variant` (`"raised"` default / `"flat"` /
  `"outlined"`) and `color` (`"default"` / `"primary"` / `"secondary"` /
  `"accent"` / `"error"`), like `pp_button`/`pp_tooltip`. Filled variants
  with a brand color fill the whole panel (with matching divider tints);
  `outlined` colors the border and the summary text. Defaults unchanged.
- `pp_paper/1` gains `color` (`"surface"` default / `"primary"` /
  `"secondary"` / `"accent"` / `"error"`), the background/foreground pair
  of the surface.

### Changed

- `pp_menu/1`'s trigger is now a real `pp_button` (hover tint, focus
  ring, ripple) instead of a bare unstyled `<button>`: `:trigger` is just
  its content, and `trigger_variant` (default `"icon"`), `trigger_color`,
  `trigger_size` and `trigger_class` style it. `trigger_variant="none"`
  keeps the old bare button for a fully custom trigger. Don't put a
  button or link inside `:trigger` (it would be nested in the trigger
  button).
- A linked `pp_card/1` (`href`/`navigate`/`patch`) is now clickable as a
  whole, actions row included: the hover tint and focus ring cover the
  entire card, and a click anywhere except on an action button follows
  the link. Before, only the title/body area reacted. The actions are
  still outside the `<a>` (valid HTML); the link is "stretched" over the
  card with an `::after` overlay, and the actions row sits above it.

## [0.2.4] - 2026-09-25

### Added

- `PhoenixPaper.Collapse` (`pp_collapse/1`) — a trigger that shows and
  hides a block of content (MUI's `Collapse`), lighter than `Accordion`:
  one component, one `id`, a `:trigger` slot. Pure CSS, with an animated
  height and content that can't be tabbed into while closed.
- `pp_list/1` gains `dense` (compact rows for every item), `nested`
  (indent the whole list one step) and `inset` (line up items without a
  leading icon with those that have one). `pp_list_item/1` gains `dense`.
- `pp_list_group/1` — a list item that expands to show a nested list
  (MUI's nested `List` inside a `Collapse`), for collapsible sidebar
  sections.
- `pp_card/1` gains `href`/`navigate`/`patch` (MUI's `CardActionArea`):
  the title and body become one link with a hover tint, focus ring and
  ripple (`ripple`, default `true`). `:actions` stay outside the link, so
  buttons in them remain valid HTML.
- `pp_typography/1` gains `color` (`"primary"`/`"secondary"`/`"accent"`/
  `"error"`/`"muted"`). Unset keeps inheriting the surrounding color.
- `pp_avatar/1` gains `color` (`"default"`/`"primary"`/`"secondary"`/
  `"accent"`/`"error"`, default `"default"` — unchanged neutral grey).
- `pp_button/1` gains `color="inherit"`: `text`/`outlined`/`icon` buttons
  follow the surrounding text color, so they stay visible on a colored
  `AppBar`/`Drawer`/`Card` without a `class` override. On `raised`/`flat`
  it's a neutral surface-variant chip.
- `pp_toggle_button/1` gains a client-side mode: `toggle` flips the
  button's pressed state on click with no server round trip (`pressed` is
  then the initial state), and `toggle_group="name"` makes a set exclusive
  like radio buttons. Uses LiveView JS commands, so the state survives
  re-renders; `on_toggle` runs extra JS (e.g. a `JS.push`) after the flip.
  The default stays controlled (`pressed` from your assigns + `phx-click`),
  now documented as such.
- `pp_tooltip/1` gains the same styling attrs as `pp_button/1`: `color`
  (`"default"`/`"primary"`/`"secondary"`/`"accent"`/`"error"`, default
  `"default"` — the unchanged inverted chip), `variant` (`"raised"`
  default / `"flat"` / `"outlined"`), `size` (`"small"`/`"medium"`/
  `"large"`) and `shape` (a `PhoenixPaper.Shape` token, default `:sm`).
  The `arrow` matches the bubble, including the outlined border.
- `pp_flash_group/1` gains `connection_notices`: the hidden "We can't find
  the internet" / "Something went wrong!" chips a generated
  `core_components.ex` shows while the LiveView socket is disconnected,
  toggled client-side by `phx-disconnected`/`phx-connected`. Titles and
  text are overridable (`client_error_title`, `server_error_title`,
  `reconnecting_text`).

### Changed

- **`pp_theme_toggle/1` is now a System / Light / Dark control by
  default** (`variant="segmented"`, like the picker in Phoenix 1.8's
  generated layout), with **System** selected by default: it removes
  `data-theme` so the page follows the OS preference, and unlike the old
  switch you can always go back to it. The selected state is pure CSS
  (keyed off `data-theme`), so every toggle on the page agrees and a
  LiveView re-render can't reset it. The choice is saved in `localStorage`
  under `"phx:theme"`, the key Phoenix 1.8's root layout already restores
  on load. It uses the `hero-computer-desktop-micro`/`hero-sun-micro`/
  `hero-moon-micro` icons. The previous two-state sun/moon switch is still
  available as `variant="switch"` (it now also saves to `"phx:theme"`).
  Each button sends `phx-value-theme`, so `on_toggle={JS.push(...)}`
  receives the chosen theme.
- **Dark mode:** `Paper` (and everything built on it: `Card`, `Accordion`,
  `Dialog`, `Menu`, `TableContainer`) now gets lighter as its elevation
  goes up — MUI's white elevation overlay — instead of relying on a shadow
  that doesn't show on a dark page. Light mode is unchanged. Apps that
  added borders to make dark surfaces visible can drop them.
- `pp_drawer/1` on desktop (`lg:` and up) now has a stacking level,
  `lg:z-30` (was `lg:z-auto`), so it always sits above a `sticky`/`fixed`
  `pp_app_bar` (`z-20`) — MUI's order, drawer over app bar. To put the app
  bar on top instead, give it `class="!z-40"`.
- `pp_typography/1`'s `caption` and `overline` variants are now
  block-level (`block`, still a `<span>`), so an eyebrow or caption sits on
  its own line without a wrapper. Add `class="!inline"` to keep one inline.
- Docs: the components whose built-in classes people most often try to
  replace through `class` (`Stack`'s `direction`/`spacing`, `Card`'s
  `padding`, ...) now name the attr to use instead; see `PhoenixPaper.Stack`
  and AGENTS.md, "Overriding built-in classes via `class`".

### Fixed

- `pp_theme_toggle variant="switch"` showed "off / sun" on a dark page
  after a reload with a saved `data-theme="dark"`, and went stale whenever
  something else changed the theme: its look came from its checkbox, which
  the server always renders at `default_checked`. An explicit
  `data-theme="dark"`/`"light"` now sets its look directly in CSS (the
  checkbox is ignored), so it's always right and survives LiveView
  re-renders.
- `PhoenixPaper.Autocomplete`'s `phx-change` form had no `id`, so
  LiveView logged a warning and couldn't restore it after a reconnect. It
  is now `"<id>-form"`.

## [0.2.3] - 2026-09-25

### Changed

- `phoenix_paper.css` now declares its own `@source "../../lib";`
  (resolved relative to the stylesheet), so Tailwind scans PhoenixPaper's
  `.ex` files automatically — whether it lives in `deps/` or is a `path:`
  dependency. The separate `@source "../../deps/phoenix_paper/lib";` line
  in your `app.css` is no longer needed and can be removed (keeping it is
  harmless).

### Removed

- `dev.exs`, the standalone live-preview component catalog script, along
  with leftover Tailwind scratch files (`imp_test/`, `input.css`). Try
  components by adding PhoenixPaper as a `path:` dependency of a real
  Phoenix project instead. None of these were part of the hex package.

## [0.2.2] - 2026-09-18

### Added

- `pp_drawer/1` gains `width` (`"sm"`/`"md"`/`"lg"`/`"xl"`, default `"md"`
  — unchanged `w-64`), applied at both the mobile and desktop breakpoint
  together.
- `PhoenixPaper.Menu` (`pp_menu/1`) — a trigger that reveals a small
  anchored popover list of actions (MUI's `Menu`/`MenuItem`): an overflow
  ("...") menu, a profile menu, etc. Closes on selecting an item, clicking
  outside, or Escape. `anchor` picks a fixed corner
  (`bottom-start`/`bottom-end`/`top-start`/`top-end`, default
  `bottom-start`).
- `pp_button/1` gains `size` (`"small"`/`"medium"`/`"large"`, default
  `"medium"`), scaling padding/gap/font-size (padding only for
  `variant="icon"`) — MUI's own `Button` `size` prop.
- `pp_snackbar/1` gains `color` (`"default"`/`"primary"`/`"secondary"`/
  `"accent"`/`"error"`, default `"default"` — unchanged inverted-monochrome
  look). A brand color paints the chip and switches the close button's and
  the `auto_hide_duration` timer bar's own contrast to match.
- `pp_snackbar/1`'s `auto_hide_duration` timer is now a visible countdown
  bar along the chip's bottom edge (shrinks over exactly the same duration
  that drives the real dismissal), not the previous invisible timing-only
  animation. `paperize={false}` still leaves it invisible-but-functional.

### Changed

- **Breaking:** the third brand color slot is renamed `tertiary` → `accent`
  everywhere: `--color-pp-tertiary`/`--color-pp-on-tertiary` →
  `--color-pp-accent`/`--color-pp-on-accent`, every component's
  `color="tertiary"` → `color="accent"`, every `pp-tertiary`/`pp-on-tertiary`
  utility class → `pp-accent`/`pp-on-accent`. No color values changed, only
  the name. Update any `color="tertiary"` or `bg-pp-tertiary`/
  `text-pp-tertiary`/etc. in your own app.
- `pp_flash_group/1`/`pp_flash/1`'s default `anchor_origin` is now
  `"top-right"` (was `"bottom-right"`).
- `pp_button/1` no longer forces label text to uppercase — it sets
  `[text-transform:inherit]` instead, matching Material 3's relaxed
  button typography.

### Fixed

- `pp_drawer/1`'s mobile backdrop could stay visible (blocking clicks)
  after opening the drawer on a small viewport and then resizing past
  `lg` without closing it first — `peer-checked:block`'s selector
  specificity was beating the `lg:hidden` meant to cancel it at the
  desktop breakpoint. The reveal is now scoped with `max-lg:` instead, so
  it's structurally absent from the generated CSS at `lg` and up rather
  than present-but-outranked.

### Removed

- The `tails` dependency (retired on hex.pm). `class` overrides are now
  plain concatenation instead of a Tailwind class-conflict merge — a
  caller's `class` reliably *adds* utilities but no longer reliably
  *replaces* one of a component's own built-in utilities for the same CSS
  property. To override a built-in class deterministically, prefix your
  override with Tailwind's `!` (important) modifier, e.g.
  `class="!bg-red-500"`. See `AGENTS.md`, "Overriding built-in classes via
  `class`".

## [0.2.1] - 2026-08-29

### Added

- `PhoenixPaper.SpeedDial` (`pp_speed_dial/1`) — a Floating Action Button
  that fans out a set of `:action` FABs on hover, click, or keyboard
  focus (MUI's `SpeedDial` + `SpeedDialAction`). Pure CSS, no JS/hook;
  `direction` (`up`/`down`/`left`/`right`), an optional `:open_icon`
  cross-fade, and per-action link (`href`/`navigate`/`patch`) or
  `on_click`.

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

[Unreleased]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.5...HEAD
[0.2.5]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/z7ealth/phoenix_paper/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/z7ealth/phoenix_paper/releases/tag/v0.1.0
