# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-10-05

PhoenixPaper is now **MD3 only**: every component is one the
[MD3 spec](https://m3.material.io/components) defines, with MD3's own
options. The components and attrs that came from other libraries (MUI's
API, ember-paper's heritage) are gone, along with the PhoenixPaper-only
color roles. What MD3 doesn't define — layout, tables, pagination,
breadcrumbs, accordions, alerts, skeletons — is left to your own
Tailwind, using the same `pp-*` tokens.

### Removed

Components MD3 doesn't define:

| Removed | Instead |
|---------|---------|
| `Box`, `Container`, `Stack`, `Grid`, `GridItem` | Tailwind layout classes (`flex`, `grid`, `gap-*`, `max-w-*`) |
| `Paper` | `Card` (MD3's container), or `bg-pp-surface-container-*` + `rounded-pp-*` |
| `Table`, `TableContainer`, `TableHead`, `TableBody`, `TableRow`, `TableCell`, `TableFooter`, `TablePagination` | a plain `<table>` styled with the `pp-*` tokens |
| `Pagination`, `Breadcrumbs` | your own links/buttons (`pp_button`, `pp_icon_button`) |
| `Accordion`, `AccordionSummary`, `AccordionDetails`, `AccordionActions`, `Collapse`, `List`'s `pp_list_group` | a native `<details>`/`<summary>`, or `pp_list_item`s you show/hide |
| `Alert` | `pp_snackbar`, `pp_dialog`, or your own banner |
| `Skeleton` | `pp_progress`/`pp_loading_indicator` |
| `Avatar` | an `<img class="size-10 rounded-pp-full">` (e.g. in a list item's `:leading`) |
| `Backdrop` | the scrim built into `pp_dialog` and the sheets |
| `ImageList`, `ImageListItem` | `pp_carousel`, or a Tailwind grid |
| `Rating`, `NumberField`, `TransferList` | `pp_radio_group`, `pp_text_field type="number"`, `pp_checkbox` lists |
| `Autocomplete`, `PowerSelect` | `pp_search_bar` with `:results`, or `pp_select` |
| `Form` (`pp_form`) | Phoenix's own `<.form>` (every input still takes `field=`) |
| `ListSubheader` | `pp_typography variant="title-small"` |
| `Spacing` (helper) | Tailwind's spacing scale |

Attrs and options MD3 doesn't have:

| Component | Removed | Now |
|-----------|---------|-----|
| `Badge` | `variant`, `color`, `overlap`, `anchor_origin`, `show_zero` | no `content` = MD3's small badge, `content` = large badge; always `error`; a count of `0` hides it; `max` defaults to `999` |
| `Card` | `padding`, `shape` | MD3's fixed 12dp corners and 16dp padding |
| `Dialog` | `max_width` | MD3's 280–560dp |
| `Snackbar` | `anchor_origin`, `transition`, the countdown bar | bottom center (bottom-start from `sm`), MD3's one entrance animation |
| `Flash` | `anchor_origin`, `transition`, leading icons | follows `Snackbar`; messages are text-only |
| `TopAppBar` | `max_width`, `disable_gutters` | — |
| `TextField` | `size="small"`, `hide_label` | MD3's 56dp field, always labelled |
| `Select` | `hide_label` | always labelled |
| `List` | `dense`, `nested`, `inset` | — |
| `ListItem` | `dense` | — |
| `ThemeToggle` | `variant="switch"`, `variant`, `default_checked` | the System / Light / Dark segmented control only |

Color roles: `success`, `warning` and `info` (with their `on-*` and
`*-container` pairs) are gone from `phoenix_paper.css`, and
`mix phoenix_paper.gen.theme` no longer generates them (`--no-status` is
gone with them). If you used them, define them in your own CSS.

### Changed

- **The PhoenixPaper LiveView hook is no longer optional.** Hooked
  components (tabs, top app bars, menus and split-button menus, tooltips,
  bottom sheets, carousels, loading indicators, the time picker) now
  render `phx-hook="PhoenixPaper"` whenever they have an `id`, and
  `config :phoenix_paper, hook: true` is gone (a leftover setting is
  ignored; delete it). Register the hook in your LiveSocket, or LiveView
  logs an "unknown hook" error for these components:

  ```js
  import PhoenixPaperHooks from "phoenix_paper"
  const liveSocket = new LiveSocket("/live", Socket, {hooks: {...PhoenixPaperHooks}, ...})
  ```

  The CSS behavior underneath is unchanged, so controller-rendered pages
  and the first paint before LiveView connects look the same as before.

## [0.4.0] - 2026-10-05

PhoenixPaper is now a **Material Design 3** library, including **M3
Expressive**. Almost every component's look changed, and many attrs were
renamed to MD3's vocabulary. This is a breaking release; the migration
table below lists every rename. Compile warnings from attr `values:`
validation point at most of the call sites to update.

### Added

- **MD3 token layer** in `phoenix_paper.css`:
  - The full MD3 color-role set: `*-container`/`on-*-container`, the
    surface-container scale (`surface-container-lowest` … `-highest`,
    `surface-dim`/`-bright`), `on-surface-variant`, `outline-variant`,
    `inverse-surface`/`inverse-on-surface`/`inverse-primary`, the fixed
    roles, `scrim` and `shadow`.
  - The MD3 baseline scheme (seed `#6750A4`) in light and dark. Dark mode
    uses tonal surfaces.
  - The status roles (`success`/`warning`/`info`) gain `-container` pairs.
- **Type scale**: the 15 MD3 roles as `pp-display-large` … `pp-label-small`
  utilities, plus Expressive `-emphasized` variants, and
  `--font-pp-brand`/`--font-pp-plain` (Roboto Flex by default; not
  loaded for you).
- **Shape**: the MD3 corner scale as `--radius-pp-*` / `rounded-pp-*`,
  including the Expressive `lg_increased`, `xl_increased` and `xxl`.
- **State layers and focus**: `pp-state-layer` (hover 8%, focus/press 10%
  of the content color), `pp-focus-ring` (3dp `secondary` outline) and
  MD3 disabled colors on interactive components.
- **Motion**: the M3 Expressive spring tokens as CSS `linear()` easings
  sampled from the real springs (`pp-motion-spatial-*` /
  `pp-motion-effects-*` utilities). `data-pp-motion="standard"` switches to
  the standard scheme, and `prefers-reduced-motion` is respected. MD3
  duration easings are available as `ease-pp-*`.
- New components:
  - `pp_icon_button/1`: standard/filled/tonal/outlined, Expressive sizes
    and widths, toggle with a selected glyph.
  - `pp_split_button/1`.
  - `pp_fab_menu/1`.
  - `pp_navigation_rail/1` (with `pp_navigation_rail_item/1` and
    `pp_navigation_rail_toggle/1`): collapsed, expanded, or responsive with
    a modal rail on small screens.
  - `pp_navigation_bar/1` (with `pp_navigation_bar_item/1`): the
    Expressive flexible bar.
  - `pp_toolbar/1`: docked or floating, standard or vibrant, with an
    optional FAB.
  - `pp_loading_indicator/1`: the Expressive shape-morphing indicator.
  - `pp_search_bar/1`, with a docked search view.
  - `pp_bottom_sheet/1` and `pp_side_sheet/1`, modal or standard.
  - `pp_carousel/1`: multi-browse, hero, uncontained and full-screen.
  - `pp_menu_item/1`.
  - `PhoenixPaper.DatePicker` (docked or modal, with an input mode) and
    `PhoenixPaper.TimePicker` (dial or input), both LiveComponents.
- Expressive features on existing components:
  - Buttons: sizes `xs`–`xl`, round/square shapes, shape morphing on press,
    toggle buttons (`selected`/`toggle`/`group`/`on_toggle`).
  - New `ButtonGroup`, standard or connected.
  - Wavy and thick progress indicators.
  - Slider sizes, the `centered` track and a value indicator.
  - Medium and large flexible top app bars with subtitles.
  - Emphasized typography.
- **Optional JS hook** (`priv/static/phoenix_paper.js`, importable as
  `"phoenix_paper"` thanks to a `package.json`, enabled with
  `config :phoenix_paper, hook: true`):
  - the sliding tab indicator;
  - drag-to-dismiss bottom sheets;
  - the scrolled top app bar and carousel masking where CSS scroll
    timelines are missing;
  - the loading-indicator morph where CSS can't animate `d`.

  Nothing requires it.
- `DatePicker` `range`: MD3's date range picker.
  - The second pick ends the range, swapping it if earlier.
  - The days between sit on a `secondary-container` band.
  - Submitted as `<name>_start`/`<name>_end`.
  - Input mode shows start and end fields.
- `pp_search_bar` `view="fullscreen"`/`"responsive"`: MD3's full-screen
  search view, CSS only. A back button closes it; `responsive` is full
  screen below `sm`.
- `pp_submenu/1`: cascading menus.
  - Opens on hover, keyboard focus or click/tap.
  - Opening it keeps the parent menu open; `Menu.close/2` collapses
    nested submenus.
- `TimePicker`: MD3's selector circle on the dial, and dragging the
  hand to any hour or exact minute with the optional hook.
- `mix phoenix_paper.gen.theme --seed "#hex"`:
  - Generates every MD3 color role, light and dark, from one seed, using
    a port of Material's HCT color science (`PhoenixPaper.Theme`,
    `PhoenixPaper.Theme.Hct`).
  - Variants: tonal spot (default), neutral, vibrant, expressive,
    fidelity, monochrome.
  - `--secondary`/`--tertiary`/`--neutral`/`--error` pin core colors.
  - The output CSS is imported after `phoenix_paper.css`.
- Edge flipping (optional hook): menus, submenus, split-button menus and
  tooltips (given an `id`) flip to the other side when they'd overflow
  the viewport.
- Tabs follow the ARIA keyboard model:
  - Only the selected tab is a Tab stop; `select/2` keeps the roving
    `tabindex` in sync.
  - Left/Right (mirrored in RTL), Home and End move between tabs,
    skipping disabled ones, and select as they go.
- `Card`: `variant` (`elevated`/`filled`/`outlined`), `:media` and
  `:subhead` slots.
- `Dialog`: a hero `icon`, plus `variant="fullscreen"`/`"responsive"`.
- `Tooltip`: `variant="rich"` with `subhead` and `:actions`.
- `Typography`: `tag` (picked independently of `variant`, via `dynamic_tag`)
  and `emphasized`.
- `TextField`: a trailing error icon and `aria-describedby`.
- `Checkbox`: `indeterminate` and `error`. `RadioGroup`: `error`.
  `Switch`: `icons`.
- `Badge`: a `tertiary` color. `Paper`: the surface-container `color`
  values and `outlined`.

### Changed

- **Breaking — renamed components:**

  | 0.3 | 0.4 |
  |-----|-----|
  | `AppBar` / `pp_app_bar` | `TopAppBar` / `pp_top_app_bar` |
  | `Input` / `pp_input` | `TextField` / `pp_text_field` |
  | `pp_button variant="icon"` | `pp_icon_button` (`icon` + required `label`) |

- **Breaking — removed components, with their MD3 replacements:**

  | Removed | Use instead |
  |---------|-------------|
  | `Drawer` / `pp_drawer` / `pp_drawer_toggle` | `pp_navigation_rail` (`variant="responsive"` gives the modal on phones) / `pp_navigation_rail_toggle` |
  | `ToggleButton` / `pp_toggle_button` | `pp_button`/`pp_icon_button` with `selected`/`toggle`/`group` |
  | old `ButtonGroup` | the new `pp_button_group` (`standard`/`connected`) |
  | `SpeedDial` / `pp_speed_dial` | `pp_fab_menu` |

- **Breaking — colors:** `accent` is renamed to `tertiary` everywhere
  (`--color-pp-tertiary`, `color="tertiary"`), MD3's name. The default
  palette is now the MD3 baseline instead of indigo/pink, and `secondary`
  is a muted companion of primary rather than a contrasting pink.
  `--color-pp-surface-variant` keeps its name with MD3's value.
- **Breaking — elevation:** six levels (0–5) instead of 0–24, with MD3
  shadows; `Elevation.class/1` clamps to 5. The dark-mode white overlay
  (`pp-surface-overlay`, `--pp-surface-tint`, `--pp-elevation-overlay`) is
  removed: surfaces use container colors. Components no longer take
  `elevation` attrs: Button, Card, Accordion, Dialog, Menu, Snackbar,
  TopAppBar and TableContainer.
- **Breaking — shape:** `Shape` emits `rounded-pp-*` classes on the MD3
  scale (`:sm` is now 8px, `:md` 12px, `:lg` 16px, `:xl` 28px). Adds
  `:start`/`:end` edges.
- **Breaking — typography:** `Typography` variants are the MD3 roles
  (`h1` → `display-large`, `h4` → `headline-medium`, `body1` → `body-large`,
  `caption` → `body-small`, `overline` → `label-small`, … — full table in
  its moduledoc). `color="muted"` → `"on-surface-variant"`.
- **Breaking — icons:** `Icon` sizes follow MD3 (`md`, the default, is
  24dp instead of 20dp).
- **Breaking — per-component attr changes:**

  | Component | 0.3 | 0.4 |
  |-----------|-----|-----|
  | Button | `variant` `raised`/`flat` | `elevated`/`filled` (default `filled`) |
  | Button | `size` `small`/`medium`/`large`, `shape` atoms, `elevation` | `size` `xs`..`xl` (default `sm`), `shape` `round`/`square` |
  | Fab | default `color="secondary"`, `size` `sm`/`md`/`lg`, inner-block label | default `primary-container`, `size` `default`/`medium`/`large`, `icon`+`label` attrs, `extended` shows the label |
  | Card | `elevation` | `variant` |
  | Chip | `variant` `filled`/`outlined`, `color`, `size`, `clickable` | `variant` `assist`/`filter`/`input`/`suggestion`, `elevated`; `clickable` only for input chips |
  | TextField | `variant="standard"`, `helper_text`, `shape` | removed / `supporting_text` / removed |
  | Select, NumberField, PowerSelect | `helper_text`, `shape` (Select/NumberField) | `supporting_text`; shape removed |
  | Tabs | `variant` `standard`/`scrollable`/`full_width`, `orientation`, per-tab `color`, `select/3` | `variant` `primary`/`secondary`, `layout` `fixed`/`scrollable`, `select/2` |
  | TopAppBar | `color` `primary`/`secondary`/`accent`, `variant` `regular`/`dense`, `elevation` | `color` `surface`/`transparent`, `variant` `small`/`center_aligned`/`medium`/`large`, `subtitle`, `scrolled` |
  | Tooltip | `color`, `variant` `raised`/`flat`/`outlined`, `size`, `shape`, `arrow` | `variant` `plain`/`rich`, `subhead`, `:actions` |
  | Snackbar | `color`, `elevation` | removed (always `inverse-surface`); `two_line` added |
  | Menu | `:trigger` slot inside a `pp_button`, `trigger_size`, `elevation`, `shape` | `trigger_icon`+`trigger_label` or `:trigger` with `trigger_variant`; `pp_menu_item/1`; `color` `standard`/`vibrant` |
  | Slider | `size` `medium`/`small` | `size` `xs`..`xl`; `track="centered"`; `value_indicator`; `stop_indicator` |
  | Progress | indeterminate circular spinner | an SVG arc; `wavy`, `thickness`, `stop_indicator`, `label` |
  | Accordion | `variant` `raised`/`flat`, `elevation` | `variant` `elevated`/`filled` |
  | Avatar | `color` `default` (grey) | container colors, default `primary`; `surface` for neutral |
  | Pagination | `shape` `circular`/`rounded`, `size` `small`..`large`, `color="accent"` | `shape` `round`/`square`, `size` `xs`/`sm`/`md`, `color="tertiary"` |
  | TableContainer | `elevation` | `variant` (default `outlined`) |
  | Dialog | default `max_width="md"` | default `lg` |

- Lists are MD3 rows (56/72dp, `body-large`), the active item is
  `secondary-container`, and subheaders use `title-small` instead of
  uppercase.
- Switch, checkbox and radio follow MD3 metrics, each with a 40dp state
  layer. Switch and checkbox `ripple` now defaults to off.
- Selected link menu items set `aria-current="page"`.
- `Divider` drops its vertical margin and uses `outline-variant`.
- Requires `phoenix_live_view ~> 1.1` (was `~> 1.0`): `Typography`
  renders through `dynamic_tag/1`'s `tag_name` attr.

### Fixed

- `pp_table_pagination/1` now puts its `id` on the root element. Before,
  the id only fed the rows-per-page menu's id, so `#my-pagination`
  selected nothing (unlike `pp_pagination/1`, whose `id` reaches its root).

### Removed

- `Drawer`, `ToggleButton`, `SpeedDial` and the old `ButtonGroup` (see the
  table above).
- The dark-mode elevation overlay utilities, and the 24-level elevation
  scale.

## [0.3.0] - 2026-10-01

### Added

- `PhoenixPaper.PowerSelect`, a searchable select in the spirit of
  ember-power-select (a `Phoenix.LiveComponent`, LiveView only):
  - Search (`search_enabled`) that ignores case and accents ("maria"
    finds "María"), on the label or a `search_field`, or with a custom
    `matcher`. Without search, typing on the focused trigger jumps to an
    option.
  - Server search: `search` is a function `term -> options`, run as an
    async task. It shows a loading message, only the latest term's
    results are shown, and blank terms fall back to `options`.
  - Groups (`%{group_name: ..., options: [...]}`, nestable, disableable)
    and disabled options.
  - `multiple`, with chips in the trigger, Backspace to remove the last
    one, and `name[]` hidden inputs.
  - Keyboard navigation, `allow_clear`, `placeholder`/
    `search_placeholder`, translatable messages, `:option` and
    `:selected_item` slots, and `field=` integration. The surrounding
    form's `phx-change` runs on every change, like a native select's; use
    `on_change` outside a form.

- `pp_form/1`, a thin layer over Phoenix's `<.form>`: same `for`/`as`/
  `action`/`:let` API, plus a spaced field column (`spacing`, default
  `:md`) and a right-aligned `:actions` slot. Plain `<.form>` keeps
  working with every `pp_*` control.
- `pp_pagination/1` (MUI `Pagination`): page numbers with ellipsis
  collapsing (`sibling_count`/`boundary_count`), prev/next and optional
  first/last buttons, `text`/`outlined` variants, `circular`/`rounded`
  shapes, three sizes and a selected-page `color`. Each page is a link
  built by `path` (`patch` by default) or fires `on_change` with
  `phx-value-page`. Pages are 1-based.
- `pp_table_pagination/1` (MUI `TablePagination`): rows-per-page menu,
  the "1–10 of 47" range and prev/next (optional first/last), as links
  via a `path` function of `(page, rows_per_page)` or as events
  (`on_page_change`/`on_rows_per_page_change`). Labels are customizable
  for translation. Pages are 1-based.
- `pp_icon/1` gains `size` (`xs`/`sm`/`md`/`lg`/`xl`, default `md` =
  the previous `size-5`, or `none` for no built-in size). A plain
  `class="size-4"` used to lose to the built-in `size-5`.
- `pp_fab/1`, `pp_button/1` and `pp_speed_dial/1` gain `position`
  (`relative` default, `fixed`, `absolute`, `sticky`). Use it to anchor
  one: `<.pp_fab position="fixed" class="bottom-6 right-6">`.
- `pp_speed_dial/1` gains `trigger_class`.

### Changed

- **Breaking:** the bundled alternate palette (`data-pp-theme="teal"`)
  is removed from `phoenix_paper.css`. Only the default palette ships; to
  re-create it (or any brand), override the `--color-pp-*` variables in
  your own `app.css`.
- **Breaking:** `pp_speed_dial/1`'s `class` now goes on the root (around
  the trigger and the actions) instead of the trigger. Move trigger
  styling to `trigger_class`.
- `pp_drawer/1`'s body is inset `px-3 py-2`, so lists no longer sit flush
  and the active item's pill no longer touches the edges. The `:header`
  row is `min-h-16 py-3` instead of a fixed `h-16`, so taller content
  grows it instead of being squeezed.
- `pp_drawer_toggle/1`'s hover tint follows the text color
  (`hover:bg-current/10`), so it reads on a colored app bar.

### Fixed

- `PhoenixPaper.Autocomplete` rendered its own `<form>`, which is invalid
  nested inside the caller's form (the browser drops it, breaking the
  search). The query input now uses `phx-keyup` and is detached from any
  surrounding form, so it's never submitted with it either.
- Form errors whose options include lists or tuples (Ecto's
  `unique_constraint`, with `fields: [:email]`, or a `validate_format`
  regex) crashed rendering. `PhoenixPaper.Helpers.translate_error/1` now
  fills in only the `%{...}` placeholders the message uses.
- `pp_input type="datetime-local"` now formats a `NaiveDateTime`/
  `DateTime` value as `YYYY-MM-DDTHH:MM`, the format the input requires
  (previously the browser showed an empty field).
- `class="fixed ..."`/`"absolute ..."` on `pp_fab`, `pp_button` and
  `pp_speed_dial` lost to the ripple's (or the dial's) own `relative`,
  so the documented corner anchoring never worked. Use `position`.

## [0.2.7] - 2026-09-25

### Fixed

- `pp_dialog/1`'s width: the `max_width` cap and `w-full` were on the
  inner panel, but the centering flex row sizes the focus-wrap container
  around it, which had no width of its own. So a `w-full` child with no
  natural width (a canvas, an empty input) collapsed the dialog to its
  text width, and a long paragraph widened the container past the panel,
  leaving the dialog off-centre. The width and cap now sit on that
  container and the panel fills it: the dialog grows to its `max_width`,
  stays centred, and still shrinks on small screens.

## [0.2.6] - 2026-09-25

### Added

- `pp_dialog/1` gains `max_width` (`"xs"`/`"sm"`/`"md"`/`"lg"`/`"xl"`/
  `"2xl"`/`"3xl"`/`"4xl"`/`"5xl"`/`"full"`, default `"md"` — the
  previous fixed width), MUI's `maxWidth`. Replaces a
  `class="!max-w-2xl"` override.
- `pp_list_item/1` passes link attributes (`target`, `rel`, `download`,
  `method`, `replace`, ...) through to its link, the same list
  `pp_button/1` accepts.
- `pp_card/1` gains `target` and `rel`, forwarded to the link in link
  mode (the card's other extra attrs land on its root `<div>`).

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

[Unreleased]: https://github.com/z7ealth/phoenix_paper/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.7...v0.3.0
[0.2.7]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.6...v0.2.7
[0.2.6]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/z7ealth/phoenix_paper/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/z7ealth/phoenix_paper/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/z7ealth/phoenix_paper/releases/tag/v0.1.0
