# AGENTS.md — PhoenixPaper base rules

> **Never commit, push, tag, or publish to hex.** Make the changes (code,
> docs, `CHANGELOG.md`, the `@version` bump in `mix.exs`) and leave them
> in the working tree; the maintainer reviews, commits, pushes, and runs
> `mix hex.publish` themselves.

PhoenixPaper is a **Material Design 3** component library for **Phoenix**
— including **M3 Expressive** — styled with **Tailwind CSS**. It ships as
a hex package (a component library, not a Phoenix app) that a Phoenix
project adds as a dependency.

**MD3 is the only source.** Every component is either one the MD3 spec
(m3.material.io/components) defines — its look, behavior and API follow
that spec — or a **composite of MD3 parts** for a common need MD3 leaves
open. The library doesn't port or imitate other component libraries
(0.5.0 removed the components and attrs that came from MUI).

A composite (since 0.5.2: `Table` and its parts, `TablePagination`,
`Pagination`, `Breadcrumbs`, `Autocomplete`, `NumberField`,
`PasswordField`) is allowed
when it's built *only* from existing MD3 components and tokens: no new
visual vocabulary, no color, shape or type value MD3 doesn't have, and
no attr options copied from another library. It reuses the library's
own components where it can (`NumberField` and `PasswordField` are a
`pp_text_field` with `pp_icon_button`s; `Autocomplete` is a
`pp_text_field` over the menu surface and `Menu.item_classes/1`).

Layout is the app's business — layout primitives, grids, spacing
helpers are written with Tailwind and the MD3 tokens below — with one
exception: MD3's own **canonical layouts** (`PaneLayout`'s list-detail
and supporting pane), because MD3's Layout foundations specify them
(window size classes, margins, spacers, fixed pane widths). Composites
whose MD3 form would be a stretch (accordions, alerts, skeletons,
ratings, steppers) stay out. A component may also go *beyond* the spec
where Phoenix needs it (`field=` form integration, `Flash` for `@flash`,
`ThemeToggle` for `data-theme`, `Upload` for LiveView uploads), again
built purely from MD3 parts.

This file is the ground truth for how the library is built. Read it before
adding or changing a component.

## Project shape

- `lib/phoenix_paper/*.ex` — one module per component, grouped as the MD3
  spec groups them:
  - Actions: `Button`, `IconButton`, `ButtonGroup`, `SplitButton`, `Fab`,
    `FabMenu`.
  - Communication: `Badge`, `Progress`, `LoadingIndicator`, `Snackbar`
    (+ `Flash`, Phoenix's `@flash` as snackbars), `Tooltip`.
  - Containment: `Card`, `Carousel`, `Dialog`, `Divider`, `List`/
    `ListItem` (+ `Avatar`, MD3's list leading element), `BottomSheet`,
    `SideSheet`.
  - Navigation: `TopAppBar`, `NavigationRail`, `NavigationBar`, `Toolbar`,
    `Tabs`/`Tab`/`TabPanel`, `SearchBar`.
  - Selection and text inputs: `Checkbox`, `Chip`, `RadioGroup`, `Menu`,
    `Select`, `Slider`, `Switch`, `TextField`, and the LiveComponents
    `DatePicker` and `TimePicker`.
  - Foundations: `Icon`, `Typography` (the type scale), `ThemeToggle`
    (light/dark), `Theme`/`Theme.Hct` (`mix phoenix_paper.gen.theme`).
  - Composites of MD3 parts: `Table` (+ `TableContainer`, `TableHead`,
    `TableBody`, `TableRow`, `TableCell`, `TableFooter`),
    `TablePagination`, `Pagination`, `Breadcrumbs`, `NumberField`,
    `PasswordField`, and the LiveComponent `Autocomplete` (with
    `multiple` input chips).
  - Layout: `PaneLayout` (MD3's list-detail and supporting-pane
    canonical layouts).
  - Phoenix integration: `Flash` (above), `Upload` (LiveView uploads).

  Helpers: `Helpers`, `Elevation`, `Shape`, `Ripple`, `Toggle`.
- `lib/phoenix_paper/components.ex` — `use PhoenixPaper.Components` imports
  every component's render function at once.
- `priv/static/phoenix_paper.css` — the MD3 token layer (color roles, type
  scale, shape, elevation, state layers, motion) plus the component
  utilities that are too much for class strings (slider, progress,
  loading indicator, button groups, carousel, ...). Consumers `@import` it.
- `priv/static/phoenix_paper.js` + `package.json` — the LiveView hook
  (see "The JS hook" below).
- `test/phoenix_paper/*_test.exs` — one test file per component.

## Material Design 3 foundations

Everything visual goes through MD3 tokens. When building or changing a
component, use these and never hand-pick a Tailwind color, radius, shadow
or font size:

- **Color roles** (`--color-pp-*`, classes `bg-pp-*`/`text-pp-*`/...):
  `primary`/`secondary`/`tertiary`/`error`, each with `on-*`,
  `*-container` and `on-*-container`; the surface scale `surface`,
  `surface-dim`/`-bright`, `surface-container-lowest`/`-low`/(plain)/
  `-high`/`-highest`, `on-surface`, `on-surface-variant`; `outline`,
  `outline-variant`; `inverse-surface`, `inverse-on-surface`,
  `inverse-primary`; the fixed roles; `scrim`, `shadow`. That's the
  whole set: no extension roles (0.5.0 removed `success`/`warning`/
  `info`). Pick the role the MD3 spec names for the component (cards
  `surface-container-low`, menus `surface-container`, dialogs
  `surface-container-high`, ...). Never add an unprefixed token.
- **Height is color.** MD3 shows a surface's level mainly with the
  surface-container scale; `pp-elevation-0..5` shadows are for the few
  components the spec gives one (elevated button/card, FAB, menus,
  sheets). There is no dark-mode overlay: dark surfaces are their own
  tones.
- **Type scale**: `pp-display-large` … `pp-label-small` utilities (one
  class sets family, size, line height, tracking and weight) and their
  Expressive `-emphasized` variants. Use complete role utilities, never a
  role plus a weight class (two classes setting `font-weight` would race).
- **Shape**: `rounded-pp-*` via `PhoenixPaper.Shape` (none, xs 4, sm 8,
  md 12, lg 16, lg_increased 20, xl 28, xl_increased 32, xxl 48, full).
  Tailwind's own `rounded-*` doesn't match the MD3 scale. Where a corner
  has to *morph* (Expressive press/selection), use an explicit length
  (`rounded-[20px]` = half a 40dp height) instead of `full`/9999px, which
  can't interpolate.
- **State layers**: interactive surfaces get `pp-state-layer` (a
  `::before` overlay in `currentColor`: 8% hover, 10% focus/press; it
  needs a positioned element) and `pp-focus-ring` (3dp `secondary`
  outline on `:focus-visible`). Controls whose state layer is a separate
  40dp circle (checkbox, radio, switch) use `pp-state-layer-target`,
  keyed off the `pp-state-group` marker on their label (deliberately not
  Tailwind's `group`, so an unrelated outer `group` can't light it).
  Disabled is MD3's: container `on-surface/10`, content `on-surface/38`
  (`opacity-38` where a whole control dims).
- **Motion**: Expressive springs as `pp-motion-spatial-{fast,default,slow}`
  (position, size, shape, colors) and `pp-motion-effects-*` (color,
  opacity). They're CSS `linear()` curves sampled from the real damped
  springs, so they overshoot the way MD3 springs do; durations are the
  springs' settle times. `data-pp-motion="standard"` swaps in the standard
  scheme and `prefers-reduced-motion` collapses durations. One-shot
  keyframe animations use the duration easings (`ease-pp-emphasized-*`).
- **Selection state lives in ARIA attributes.** Toggle buttons, filter
  chips, tabs and button groups style their selected look off
  `aria-pressed`/`aria-selected` (`aria-pressed:bg-pp-primary`), never
  off an assign. The same class set then serves server-controlled
  (`selected={@x}`) and client-toggled (`Phoenix.LiveView.JS`) state, and
  LiveView keeps JS-command attributes across patches. See
  `PhoenixPaper.Toggle`.
- **Custom variants**: `phoenix_paper.css` defines `@custom-variant`s
  where one condition needs several selectors (`pp-rail-expanded:` /
  `pp-rail-collapsed:` for the navigation rail). Prefer one of those over
  repeating a three-selector condition on every class.

## The JS hook

PhoenixPaper's rule used to be "no JS hooks". Since 0.4.0 it is: **one
hook, registered as part of setup, does what CSS can't do (everywhere);
every component still renders and works without it running** (hooks
don't run on controller-rendered pages or before LiveView connects, so
the CSS behavior underneath covers first paint and dead views). `priv/static/phoenix_paper.js`
exports one LiveView hook, `PhoenixPaper`, that dispatches on what it's
mounted on (tabs' sliding indicator, top app bar scroll state, loading
indicator morph, bottom-sheet drag, carousel mask, time-picker dial drag,
and edge flipping for menus, submenus and tooltips). Edge flipping sets
`data-pp-flip` through `hook.js()` (so patches keep it) and is styled by
**unlayered** rules at the end of `phoenix_paper.css`, which beat
Tailwind's layered utilities without `!important`. Components render
`phx-hook={Helpers.hook(id)}`, which is `"PhoenixPaper"` whenever an id is
available (LiveView needs one for a hook) and `nil` otherwise. In 0.4.0
it was opt-in behind `config :phoenix_paper, hook: true`; since 0.5.0
there's no switch, and an app that skips registering the hook gets
LiveView's "unknown hook" console error, which is the intended signal.

When adding hook behavior: a CSS-only version must still work (it's what
dead views and first paint get); put the hook on an element that doesn't already
carry one (`focus_wrap/1` has LiveView's own FocusWrap hook — the bottom
sheet's hook sits on its handle for that reason); and reapply anything the
hook sets on the element in `updated()`, since a patch resets it.

Small inline snippets (`onclick`/`oninput`/`onkeydown` — ripple, slider
sync, escape-to-close) remain fine and preferred for tiny behaviors.

## Component conventions

- One module per component, one public render function named `pp_<name>`
  (`pp_button/1`, `pp_card/1`, `pp_checkbox/1`, `pp_icon/1`, ...). The `pp_`
  prefix is mandatory — it is what lets `use PhoenixPaper.Components` be
  imported into a Phoenix app's `html_helpers` without colliding with the
  app's own generated `core_components.ex` (`button/1`, `input/1`, `icon/1`)
  or with daisyUI-influenced naming.
- Every component accepts:
  - `paperize` (`:boolean`, default `true`) — see the contract below.
  - `class` (`:any`, default `nil`) — concatenated after the component's
    own built-in classes (see "Overriding built-in classes via `class`"
    below for what that does and doesn't guarantee).
  - `rest` (`:global`) — for `phx-*` bindings, `id`, `data-*`, etc.
- Register new components in `PhoenixPaper.Components`' `__using__/1` in the
  same change.
- Attrs follow MD3's own vocabulary and options (`variant` names, sizes,
  colors are the spec's). Don't add an attr for something MD3 fixes
  (a dialog's width, a snackbar's placement, a card's corners) — fixed
  values belong in the component's classes.
- The one-module-per-component rule bends for a small control that's
  meaningless without its parent component — `PhoenixPaper.NavigationRail`
  exports `pp_navigation_rail/1`, its items and its
  `pp_navigation_rail_toggle/1` menu button from
  the same module. It doesn't bend for anything independently reusable:
  `PhoenixPaper.ListItem` is its own module (and works standalone, e.g.
  inside a `Card`) rather than living inside `PhoenixPaper.List`, because a
  styled list item is useful on its own. When in doubt, split it out.

## Conditional root tag: link vs. static element

HEEx can't parameterize a tag name (`<{@tag}>` isn't valid), so a component
that should render as `<a>` when it's a link and a plain `<div>`/`<span>`/
`<button>` otherwise (`ListItem`, `Button`) needs two `:if`/`:if={!...}`
branches in the same template, each rendering its own root element. Factor
the shared inner markup into a private function component (e.g. `ListItem`'s
`item_content/1`, `Button`'s `button_content/1`) called from both branches
instead of duplicating it — passing the same `assigns` map through works
fine since it's still just a Phoenix.Component function receiving assigns,
not a macro needing anything special.

`Button`'s link branch (`href`/`navigate`/`patch` set → `Phoenix.Component.link/1`)
has one wrinkle `ListItem`'s
doesn't: `<button>` has a native `disabled`, `<a>` doesn't. So the link
branch sets `aria-disabled="true"` (gated on `disabled or loading`)
instead of `disabled`, and every disabled style is written twice, as
`disabled:` and `aria-disabled:` (MD3's `on-surface/10` container,
`on-surface/38` content, `pointer-events-none`), so both branches look
the same. `type` is dropped in link mode. Ripple flows through `<.link>`
unchanged — it already did for `ListItem`, and `onclick` (not `onpointer*`)
is what makes that legal through a function component (see "The ripple
effect").

`Typography` doesn't need branches: since 0.4.0 it renders through
Phoenix's built-in `dynamic_tag/1` (`tag_name`, LiveView ≥ 1.1). The
variant picks a default tag (`display-*` → `h1`, `body-*` → `p`, ...) and
`tag` overrides it from an allowlist, so the visual role and the document
outline are independent. Prefer `dynamic_tag` over `:if` branches when a
component needs a caller-chosen tag; keep the branches for link-vs-static
roots, where the two elements need different attributes anyway.

## The ripple effect

`PhoenixPaper.Ripple` implements the Material ripple (a circle expanding
from the click point, then fading) as a small vanilla inline `onclick`
snippet — no JS hook, no bundler. Every genuinely click-driven component (`Button`, `IconButton`, `Fab`,
a linked `ListItem`, ...) exposes a `ripple` boolean attr, **default
`true`**, wired identically:

```elixir
class={Helpers.classes(@paperize, [..., Ripple.container_classes(@ripple)], @class)}
onclick={Ripple.on_click(@ripple)}
```

Three things worth knowing before touching this:

- **`relative` loses to a caller's `fixed`/`absolute`.** Tailwind emits
  `.relative` after `.absolute`/`.fixed` in its stylesheet, so
  `container_classes/1`'s `relative` silently beat a
  `class="fixed bottom-6 right-6"` on a `Fab` (the documented way to
  anchor one, until 0.3.0). `Button` and `Fab` now take a `position` attr
  (`relative`/`fixed`/`absolute`/`sticky`) and call
  `Ripple.container_classes/2`, which emits exactly one position class
  plus `overflow-hidden`. Any of the four gives the ripple span its
  containing block. `FabMenu` takes `position` on its root.
- **It has to be `onclick`, not `onpointerdown`/`onmousedown`.** Phoenix's
  HEEx compiler statically validates `on*` attributes against a fixed
  allowlist for function components (see
  the `@globals` list in Phoenix.Component's internal `Declarative` module) — that list has `onclick`
  and the `onmouse*` family, but no `onpointer*` events at all. This only
  bites when the attribute has to pass through a function component like
  `Phoenix.Component.link/1` (which `ListItem` renders through when it's a
  link) — a raw HTML tag like `<button>` isn't attr-validated at all, so
  `onpointerdown` would have compiled fine on `Button`/`IconButton`/`Fab`
  specifically, but silently failed to compile the moment the exact same
  code was reused on `ListItem`. Using `onclick` everywhere keeps the
  helper and its usage identical across every component instead of one
  component needing a different event name than the rest.
- **`ripple` is independent of `paperize`** — it's wired outside the
  `Helpers.classes/3` gate, so it stays active even under `paperize={false}`
  (like `Checkbox`'s hidden-input trick, it's functional/behavioral, not
  skin). Only `Ripple.container_classes/1`'s `relative overflow-hidden`
  (needed to position/clip the ripple) lives inside `paper_classes` and
  gets stripped by `paperize={false}` along with everything else — add
  those two classes back yourself via `class` if you want ripple to render
  correctly on a de-paperized component.

## `cursor-pointer` on clickable elements

Browsers default `<button>` (and `<select>`) to `cursor: default`, **not**
`pointer` — only `<a href>` gets a pointer cursor for free. Every clickable
non-anchor element a component renders needs an explicit `cursor-pointer`
class, or hovering it gives no visual affordance that it's clickable at
all. This was missed on every `<button>` in the library for a while
(`Button`, `Fab`, ...) before being caught and fixed — when adding a new component with a raw `<button>` (or `<select>`),
add `cursor-pointer` to its base classes from the start. A `<.link>` or raw
`<a>` doesn't need it (browsers already do this correctly for anchors), and
neither does a non-interactive element — `ListItem`'s static (non-link)
branch deliberately does *not* get `cursor-pointer`, since there's nothing
to click.

## The `paperize` contract

Every component takes a `paperize` boolean attribute, **default `true`**.

- `paperize={true}` (default): the component renders with PhoenixPaper's
  Material Design classes (the "paper" skin) — colors, elevation, shape,
  typography. A caller-supplied `class` is concatenated after them, so a
  small tweak doesn't *require* dropping into `paperize={false}` — but
  see "Overriding built-in classes via `class`" below: without a
  class-merge step, overriding a specific built-in utility (rather than
  just adding a new one) needs Tailwind's `!` prefix to reliably win.
- `paperize={false}`: **all** of the component's built-in classes are
  dropped. Only the caller's `class` and `rest` attrs render. The DOM
  structure needed for the component to function stays (e.g. the
  hidden-input trick on `Checkbox` for unchecked-value submission), but
  nothing about its *appearance* is assumed — the caller has a clean slate.

Implementation: `PhoenixPaper.Helpers.classes/3` is the single gate every
component calls through:

```elixir
Helpers.classes(@paperize, paper_classes(...), @class)
```

Never hand-roll this gate inside a component — if `Helpers.classes/3`
doesn't fit a new component's needs, fix it there.

One attr doesn't go through that gate and needs its own handling:
`ripple` (`Button`, `IconButton`, `Fab`, `ListItem`, ...) fires via an
`onclick` attribute, not a class, so `Helpers.classes/3` dropping
`paper_classes(...)` under `paperize={false}` doesn't touch it — the
ripple would still fire with nothing to size/clip it. Every ripple-capable
component computes an effective `ripple and paperize` value and uses
*that* everywhere `ripple` would otherwise appear (see
`PhoenixPaper.Ripple`'s moduledoc). Keep that pattern for any new
component that adds `ripple`.

## Overriding built-in classes via `class` — no merge, use `!important`

PhoenixPaper does **not** depend on a Tailwind class-merging library.
Earlier versions routed every `class` through `PhoenixPaper.Tails`, a
`Tails.Custom` instance (from the `tails` hex package) configured to
recognize `pp-*` as a color family so it could tell e.g. `text-pp-primary`
(color) apart from `text-xs` (font-size) when deciding whether two
same-prefixed classes conflict. `tails` was retired on hex.pm (all
versions marked "Deprecated" — its own last release was May 2024, with no
maintained drop-in successor: the most-downloaded alternative, `tw_merge`,
explicitly documents that it doesn't support extending its color/token
recognition at all, which is the one feature this library actually needed)
— rather than either vendor `tails`' own ~2000-line merge engine into this
codebase permanently or depend on a library that can't do what we need,
`Helpers.classes/3` and `Helpers.toggle_label_classes/1` now just
concatenate: `[paper_classes, extra_class]`, flattened and space-joined,
nothing more. See `PhoenixPaper.Helpers`'s moduledoc.

**What this means in practice**: a caller's `class` reliably *adds* new
utilities, but does **not** reliably *replace* a built-in one that targets
the same CSS property — both classes render, and which one visually wins
is decided by Tailwind's own generated stylesheet order (fixed by
Tailwind's internal utility ordering, not by where the class appears in
your `class={...}` attribute), so it's not something to rely on. To
override a specific built-in utility (a color, a size, a border width, a
padding, ...), prefix your override with Tailwind's `!` (important)
modifier — e.g. `class="!bg-red-500"` to override a button's default
`bg-pp-primary`, `class="!size-8"` to override `Icon`'s preset
`size-*`. `!` beats a non-`!` class regardless of stylesheet order, so it's
the one deterministic way to win. This was already the documented
workaround for the one case even `tails` itself couldn't merge (`size-*`,
a shorthand its ruleset predates); it's now the standard pattern for *every* override, not just that one case.

**Point people at the attr first.** Most of the overrides people reach
for already have an attr that *changes* the built-in class instead of
fighting it — a class conflict there isn't a bug to work around with `!`,
it's a sign the attr was missed. When a component emits a size/color
class from an attr, name that attr in its moduledoc as the way to change
it. The current set:

| Component | Built-in class | Change it with |
|-----------|----------------|----------------|
| `Card` | surface color, border, shadow | `variant` |
| `Button`/`IconButton` | colors, height/padding/type, corners | `variant`, `color` (incl. `inherit`), `size`, `shape`, `width` |
| `Icon` | `size-*` | `size` (`none` = no built-in size) |
| `Fab`/`FabMenu`/`Button`/`IconButton` | `relative` | `position` |
| `Typography` | type role, color | `variant`, `emphasized`, `color` |

Use `!` only for what no attr covers. A responsive or state variant
(`md:flex-row`, `hover:...`) adds a *different* class instead of
replacing one, so it doesn't need `!` at all.

If a new component needs the *default itself* to be conditional rather
than asking every caller to reach for `!`, prefer branching in the
component's own `paper_classes/...` (a `case`/`cond` picking one literal
string, per "Tailwind class safety" below) over expecting `class` overrides
to replace it — that keeps the override-free path.

## Tailwind class safety — no dynamic class names

Tailwind's compiler does not execute Elixir: it scans raw source text for
whole class-name substrings. **A class name built by string interpolation or
concatenation from a runtime value will not be detected**, and Tailwind will
silently omit it from the compiled CSS.

Rules:

- Never write `"bg-#{color}-500"` or `"pp-elevation-#{level}"`-style
  interpolation to produce a class name.
- Instead, enumerate every case as a literal string in an explicit
  `case`/`cond`/pattern-matched function clause, in a `.ex` file that's
  covered by the consumer's Tailwind source scan. See
  `PhoenixPaper.Elevation.class/1`, `PhoenixPaper.Shape.class/1`, and
  `PhoenixPaper.Button`'s `color_classes/2` for the pattern.
- The same applies to variant-prefixed combinations (`hover:pp-elevation-4`)
  — the whole prefixed token must appear literally somewhere, not be
  assembled at runtime by concatenating a prefix and a helper's return
  value. `PhoenixPaper.Elevation` shows the pattern: `class/1` and its
  `hover_class/1` twin each spell out every level as a literal
  (`"pp-elevation-2"`, `"hover:pp-elevation-2"`, ...).

## CSS-only interactive state: `peer-*` vs `has-[:checked]:`

Several components (`Checkbox`, `Switch`, `RadioGroup`) fake a
custom-styled control (a box, a track, a circle) around a real, visually
hidden `<input>`, purely in CSS, no JS. Two different Tailwind mechanisms
apply depending on where the styled element sits relative to the input, and
using the wrong one silently does nothing (it doesn't error — it just never
matches, and the "checked" look never appears):

- **`peer-checked:`** (`.peer:checked ~ .peer-checked\:X`, a sibling
  combinator) — use this when the styled element is a **sibling** of the
  input, both children of the same parent (e.g. `Checkbox`'s checkmark glyph
  sitting right after the `.peer` input).
- **`has-[:checked]:`** (`&:has(:checked)`) — use this when the styled
  element is an **ancestor** of the input (e.g. `Checkbox`'s outer box
  *contains* the input as a child, so it has to react to its own descendant,
  not a sibling — `peer-checked:` on that ancestor was a real bug once and
  never actually painted the box).

A third variant, for toggling something from *outside* its DOM subtree
entirely (the navigation rail's modal panel, opened by a menu button that
lives inside the `TopAppBar`, nowhere near the rail): a plain `<label for={checkbox_id}>`
checks a checkbox regardless of where the label sits in the document — label
targeting is id-based, not sibling-based. Only the elements that need to
*react* to the checkbox (the rail, its scrim) have to be its
actual siblings for `peer-checked:` to reach them; the button that flips it
doesn't.

`FabMenu` uses the same checkbox, plus a click-away `<label>` for it.

## Stateless function components vs. `Phoenix.LiveComponent`

Every component is a stateless `Phoenix.Component` function (`pp_*/1`) by
default — that's the whole point of the `pp_` import convention. Reach for a
`Phoenix.LiveComponent` only when a component needs interactive state a
single render pass can't express from its attrs alone (`DatePicker`'s
viewed month and pending date, `TimePicker`'s dial state,
`Autocomplete`'s query and filtered options). Those three are the only
such components on purpose: they aren't imported by
`PhoenixPaper.Components` (there's no function to import — they're used
directly as `<.live_component module={PhoenixPaper.DatePicker} ... />`),
they only work inside a LiveView (not a plain dead/controller-rendered
page), and that limitation is called out in their moduledoc. Default to a
stateless function component; justify a `LiveComponent` explicitly.

All three tell the caller's form about changes the same way: hidden
inputs carry the value, and after each change the server renders a fresh
`<span id="<id>-changed-N" phx-mounted={JS.dispatch("input", ...)}>`.
The id changes, so it's a new element, and `phx-mounted` fires after the
patch, when the hidden inputs already hold the new value; the dispatched
`input` event bubbles into the form's `phx-change`, like a native input's.
A LiveComponent has no `attr` defaults (an omitted attr is simply absent),
so `update/2` fills `@defaults` with `assign_new/3` — correct here, unlike
in function components (see the `assign_new/3` gotcha below). They're
tested with `live_isolated/3` through `PhoenixPaper.TestEndpoint` in
`test/support` (needs the test-only `lazy_html` dep).

## Containment: `Card`

`Card` renders MD3's three cards itself (`elevated`
`surface-container-low` + level-1 shadow, `filled`
`surface-container-highest`, `outlined` `surface` + `outline-variant`
border), with MD3's fixed medium (12dp) corners and 16dp content padding.

**Link attributes need a route to the `<a>`.** A linkable component whose
`rest` lands on the link itself (`Button`, `ListItem`) must list the
non-global link attrs in `attr(:rest, :global, include: ~w(target rel
download hreflang referrerpolicy method csrf_token replace))` — `target`
and `rel` aren't HTML globals, so without the `include` Phoenix rejects
them at compile time. A component whose `rest` lands on a *wrapper*
instead (`Card`: `rest` goes on the card root, the link is inside it)
needs explicit `target`/`rel` attrs forwarded to the link, or they'd end
up on a `<div>` where they do nothing.

**`Card`'s link mode is a "stretched link"** (MD3's clickable card). The
title + body `<a>` gets an `after:absolute after:inset-0` overlay against
the `relative` card root, so the whole card, actions row included, is
the click/hover/focus target, while `:actions` stays outside the `<a>`
(a button inside a link is invalid). The hover tint and focus ring are
drawn on that `::after` (`hover:after:bg-...`), not the link box. The
actions row is `relative z-10` to sit above the overlay, plus
`pointer-events-none [&>*]:pointer-events-auto` so its buttons keep their
clicks but the gaps between them fall through to the link. Verified with
`document.elementFromPoint` in Chromium: title, body and the actions-row
gap all hit the card link, and the action button hits itself.

## Composites: tables, pagination, breadcrumbs, `NumberField`, `Autocomplete`

Removed in 0.5.0 with the rest of the MUI-derived components, brought
back in 0.5.2 rebuilt as composites of MD3 parts (see the rule at the
top). What each is made of, and what was dropped on the way back:

- **The Table family** composes like an HTML table (`pp_table` >
  `pp_table_head`/`pp_table_body`/`pp_table_footer` > `pp_table_row` >
  `pp_table_cell`), inside an optional `pp_table_container` that draws a
  card surface (`Card`'s three variants, fixed medium corners) and
  scrolls horizontally. Cells: `body-medium` in `on-surface`, headers
  `title-small` in `on-surface-variant`, `outline-variant` dividers, the
  8% state layer on row hover, `secondary-container` + `aria-selected`
  for a selected row. Sortable headers use an MD3 icon arrow, the focus
  ring and `aria-sort`. `sticky_header` and the dividers reach their
  cells through descendant selectors (`[&_thead]:sticky`,
  `[&>tr]:border-b`), since HEEx can't push attrs into children the
  caller wrote. MUI's `dense` and `striped` didn't come back, which also
  let `selected` drop the `!bg-` it needed to beat the stripe.
- **`Pagination`** is a row of 40dp MD3 standard icon buttons; the
  current page takes `secondary-container` and `aria-current="page"`.
  It shows first/last/current ±1 (`items/2`, doctested, constant length
  so the bar doesn't change width). MUI's `sibling_count`,
  `boundary_count`, first/last buttons and variant/shape/size/color
  options didn't come back.
- **`TablePagination`** is a `pp_menu` rows-per-page picker, the range
  text and two `pp_icon_button`s, needs an `id` (for the menu), and is
  1-based like `Pagination`. Both link (`path` + `link`) or fire events
  (`on_*`), never both; a control that can't move is a disabled button,
  never a link to page 0. Labels are `rows_per_page_label` and
  `range_label` (renamed from MUI's).
- **`Breadcrumbs`**: linked items are compact text buttons (`label-large`
  `primary`, state layer, focus ring), the current item (the one without
  a link — not inferred from position) is `on-surface` text, and the
  separator is a chevron icon (`rtl:rotate-180`). It wraps rather than
  collapsing; MUI's `max_items` collapse and custom separator didn't come
  back. Its `:item` slot attrs have no defaults (slot attrs can't), so
  they're read with `item[:href]`, never `item.href`.
- **`NumberField`** is a `pp_text_field type="number"` (so the floating
  label, notch, supporting text and errors are the text field's) with
  two `pp_icon_button` steppers in `:end_adornment`, both trailing — a
  40dp leading button would misalign the outlined notch, whose offset is
  sized for a 24dp icon. The steppers call `stepUp()`/`stepDown()` and
  dispatch an `input` event (inline `onclick`, `ripple={false}` so it
  doesn't fight the ripple's own `onclick`).
- **`Autocomplete`** (LiveComponent) is a `pp_text_field` acting as an
  ARIA combobox over a `listbox` drawn as the MD3 menu surface, whose
  options reuse `Menu.item_classes/1` (public, `@doc false`) so they look
  exactly like menu items without copying class strings — but keep
  `role="option"`, which `pp_menu_item`'s fixed `menuitem` role wouldn't
  allow. The text box is detached from the caller's form (`form` points
  at a missing id, no `name`, `phx-keyup` instead of `phx-change`); a
  hidden input carries the value and the changed-span dispatch tells the
  form. Arrow keys move DOM focus through the options via one inline
  `onkeydown` (focus can't be undone by a patch); Escape and click-away
  close it. Filtering folds case and accents (NFD, strip `\p{Mn}`).

## Composites added later in 0.5.2: `PasswordField`, `Autocomplete` `multiple`, `Upload`, `PaneLayout`

- **`PasswordField`** is a `pp_text_field type="password"` whose trailing
  icon is a `pp_icon_button` *toggle* (`hero-eye` / `selected_icon`
  `hero-eye-slash`, `aria-pressed`) — MD3's visibility-icon pattern. The
  icon button's `on_toggle` adds `JS.toggle_attribute({"type", "text",
  "password"}, to: "#id")`, so one `phx-click` flips both, client-side.
  JS-command attributes survive LiveView patches; a script setting
  `input.type` directly would be reset to `password` by the next patch.
  Checked in headless Chromium with the real LiveView client (password →
  text → password, `aria-pressed` following).
- **`Autocomplete`'s `multiple`** turns picks into MD3 input chips
  (`pp_chip variant="input"`, `deletable`) **inside the text field**, as
  MD3 shows them, and keeps the listbox open (`aria-multiselectable`);
  picking a selected option removes it, and Backspace in an empty box
  clicks the last `chip-delete` control (from the same inline
  `onkeydown`). The value is a list submitted as `name[]`, plus an empty
  `name[]` sentinel so removing every chip still submits the field
  (callers filter `""`).
- **`TextField`'s `:chips` and `:menu` slots** make that possible.
  `:chips` renders in a wrapping flex row before the input (the input
  becomes a `min-w-[4ch] flex-1` item); while it's given, the label uses
  static raised classes and the outlined notch is held open, instead of
  the `peer-[:not(:placeholder-shown)]`/`has-[...]` triggers — the server
  knows the slot is there, so no CSS has to detect chips. The trigger is
  the slot being *given*, not rendering something: callers pass it with
  `:if={list != []}` (an always-present slot rendering nothing raised the
  label with zero chips — caught in a screenshot, now tested). `:menu`
  renders inside the field box (the positioning ancestor), so
  `Autocomplete`'s listbox at `top-full` sits under the box however tall
  the chips make it, and focus in the options keeps the field's
  `focus-within` (MD3's focused field while its menu is open). Measured
  in Chromium with the compiled CSS: outlined chip fields stay 56px
  (12px + a 32px chip + 12px), filled ones are 64px (room for the raised
  label above the chips), the menu sits 4px under the box.
  A HEEx trap found the same way: `{@flag && render_slot(...)}` renders
  the literal text `false` when the flag is false; use
  `{if @flag, do: ...}`. The text field tests assert no `>false<` text.
- **`Upload`** wraps `live_file_input/1`. The drop zone is
  `surface-container-low` + `outline-variant`, with MD3's dragged state
  (16% layer, `primary` outline) keyed off the `phx-drop-target-active`
  class LiveView adds during a drag. The browse button is a tonal
  `pp_button` whose inline `onclick` clicks the hidden file input
  (`ripple={false}`, so it doesn't collide with the ripple's own
  `onclick`). Each entry: `live_img_preview/1` (images) or a document
  icon, a linear `pp_progress` while uploading, `upload_errors/2` mapped
  to text (`error_to_string` overrides), and a cancel `pp_icon_button`
  sending `on_cancel` with `phx-value-ref`. Tested through LiveViewTest's
  real upload protocol (`file_input/4` + `render_upload/3`), which joins
  an upload channel — that's why `test_helper.exs` starts a PubSub for
  `PhoenixPaper.TestEndpoint`. Two test-only quirks: `render_upload/3`
  can only stop at whole chunks, so the test files are 10 bytes (10% and
  40% split exactly; a 3-byte file reports 33%/66% and logs a warning),
  and cancelling an in-progress entry removes it when its channel
  exits, just after the click's reply — assert on the next `render/1`.
- **`PaneLayout`** (`pp_list_detail`, `pp_supporting_pane`) follows MD3's
  Layout foundations: window size classes compact < 600dp ≤ medium <
  840dp ≤ expanded, as literal `min-[600px]:`/`min-[840px]:` variants
  (Tailwind's defaults are 640/768/1024 and don't match); 16dp margins
  on compact, 24dp from medium; a 24dp spacer; 360dp fixed panes.
  List-detail shows one pane below 840dp (`show_detail` picks which) and
  both from 840dp; the supporting pane stacks below 840dp. Panes are
  plain regions without a surface. Under `paperize={false}` only the
  `hidden`/`flex` visibility classes stay (they're what makes it a
  layout); margins, spacer and widths go.

## Navigation: `TopAppBar` (renamed from `AppBar`, earlier `Navbar`)

MD3's top app bar is **surface-colored**, not primary: `bg-pp-surface`,
turning `surface-container` when content scrolls under it. The scroll
color change is CSS (`pp-top-app-bar-scroll`, an `animation-timeline:
scroll(nearest)` animation over the first 8px) where scroll-driven
animations exist; the JS hook sets `data-pp-scrolled` elsewhere,
and `scrolled` forces it from the server. Variants: `small`,
`center_aligned`, and the Expressive flexible `medium`/`large` (title on
its own row) with `subtitle`.

This removed 0.3's biggest footgun: brand-colored bars made `text`/icon
buttons inside them invisible (`text-pp-primary` on `bg-pp-primary`).
On a surface bar the default icon-button color (`on-surface-variant`) is
already right; `color="inherit"` stays the answer on colored surfaces
(the vibrant `Toolbar`, a filled card).

The row's layout classes stay unconditional under `paperize={false}` (no
inner `class` to rebuild them with) — a deliberate exception to "paperize
drops everything".

## Navigation: stacking order

Fixed layers: `TopAppBar`'s `sticky`/`fixed`/`absolute`
positions are `z-20`, as are a fixed `NavigationBar`/`Toolbar`; the docked
navigation rail is `md:z-30`; the modal rail's scrim `z-30` and panel
`z-40`; menus `z-40`; dialogs and sheets `z-50`. Keep new fixed/sticky
components on this ladder.

## Navigation: `NavigationRail` (replaces `Drawer`), `NavigationBar`, `Toolbar`

M3 Expressive retires the navigation drawer in favor of the expanded
navigation rail, so 0.4.0 removed `Drawer`. `pp_navigation_rail/1` keeps
the drawer's mechanism — hidden checkboxes, a scrim `<label>` and the
rail rendered as siblings, with `pp_navigation_rail_toggle/1` as
`<label for>`s that work from anywhere (the top app bar) — but with
**two** checkboxes for a `variant="responsive"` rail: below `md`,
`data-pp-rail-toggle` (`#<id>-toggle`, starts from `default_open`) opens
the modal expanded rail; from `md`, the rail is docked, 96dp collapsed,
and `data-pp-rail-expand` (`#<id>-expand`, starts from
`default_expanded`) expands it to 280dp. `collapsed`/`expanded` are fixed.

Until 0.5.2 it was one checkbox for both, so `default_expanded` — meant
for the desktop — also opened the modal (and its scrim) on every phone
page load (reported from a real site). With two checkboxes, every class
that reacts to one names it: named peers (`peer/modal`, `peer/expand` on
the inputs; `max-md:peer-checked/modal:`, `md:peer-checked/expand:` on
the rail and scrim), since an unnamed `peer-checked:` fires for any
checked `.peer` sibling. The `pp-rail-expanded:`/`pp-rail-collapsed:`
variants key off `[data-pp-rail-expand]`. The toggle is two labels, one
per checkbox, shown only at their breakpoint (`md:hidden` /
`max-md:hidden`); `modal_only` keeps the first. Verified in Chromium on
the compiled CSS at 390px and 1280px with `default_expanded`: phone loads
with the modal closed and opens it from the button; desktop loads
expanded (280px) and collapses (96px) from the button.

Every element that changes between collapsed and expanded uses the
`pp-rail-expanded:`/`pp-rail-collapsed:` custom variants
(`phoenix_paper.css`). Each variant names the three-way condition
(variant attribute, viewport, checkbox state) once, matching both the rail
itself and its descendants through zero-specificity `:where()`. Items
are a separate function component in the same module (meaningless
outside the rail), as are the badge and the FAB that extends when the
rail does.

0.3's colored-drawer machinery (compound selectors re-coloring nested
`List` items) is gone with it: MD3 rails are surface-colored and the
active item is a `secondary-container` indicator.

`NavigationBar` is the Expressive flexible bottom bar; its items read the
bar's `data-pp-layout` through a named `group/bar`
(`group-data-[pp-layout=horizontal]/bar:flex-row`) to put labels beside
icons on medium screens. `Toolbar` (docked or floating, standard or
vibrant) replaces MD3's bottom app bar.

## Navigation: `Tabs`, `Tab`, `TabPanel`

Switching is `Phoenix.LiveView.JS` (`Tabs.select/2`): set every tab's
`aria-selected` false, this one true, hide every panel, show this one.
`peer-*`/`has-*` can't express "which one of N", and the panel usually
isn't a sibling of the tabs, so CSS alone can't do it. Since 0.4.0 the
selected look is pure CSS off `aria-selected` (label color, indicator
opacity), so `select/2` no longer adds or removes classes — and the
variant (`primary`/`secondary`) is read from the root's `data-pp-variant`
through `group/tabs`, so it's set once instead of per tab.

Hidden panels use the `hidden` **class**, unconditionally: Tailwind's
preflight makes the `[hidden]` attribute `display: none !important`, which
`JS.show`'s inline `display` can't beat.

The primary indicator is as wide as the label because it's positioned
inside the label's own box. Its slide from tab to tab is the JS hook's
(a FLIP animation on the spring), and is instant without it.
Verified with a unit test pattern-matching `select/2`'s exact op list,
like every JS-command component.

## Selection: `Menu`

`pp_menu/1` is MD3's menu: a trigger that reveals a small anchored list
of actions (an overflow menu, a profile menu). The checkbox/
`peer-checked:` trick other reveal components use (`NavigationRail`,
`FabMenu`) can only express "is *some* sibling checked," with no way to close itself on an outside click or on
selecting an item — both baseline-expected menu behavior — so `Menu` uses
the same `Phoenix.LiveView.JS` + `phx-click-away` mechanism `Dialog` uses
for its own backdrop-click case, not a new mechanism.

**One real difference from `Dialog`'s architecture**: `Dialog`'s trigger
lives wherever the caller puts it on the page (`phx-click={Dialog.show(id)}`
on a button anywhere), fully decoupled from the dialog markup itself,
because a full-screen modal doesn't need to be positioned relative to
anything. A menu's popover *does* — it has to render right under its own
trigger — and doing that in CSS (the hook only adds edge flipping)
means `absolute`-positioning the panel against a `relative` ancestor that
also contains the trigger. So unlike `Dialog`, `pp_menu/1` renders
*both* the trigger and the panel itself, as one component, and the
`:trigger` slot only supplies the trigger's inner content, not a whole
independent element elsewhere on the page.

**Closing an item closes the menu — via bubbling, not cooperation.**
`phx-click={close(@id)}` sits on the panel wrapper itself; clicking any
item inside (a `pp_menu_item`, a plain link, anything) runs that item's own
click handling first, then the native DOM click event bubbles up to the
panel's own listener and closes the menu — zero coordination needed from
whatever `:inner_block` renders. An element that must *not* close the
menu just needs a `phx-click` of its own: LiveView runs only the nearest
`phx-click`, so the panel's never fires. That's how `pp_submenu/1`'s
trigger keeps the menu open (its `phx-click` sets its `aria-expanded` and
moves focus into the submenu, which CSS shows off that attribute);
verified with the real LiveView client in Chromium. `close/2` resets
nested submenus' `aria-expanded`.

**Positioning is unconditional, not gated by `paperize`.** The panel's
`absolute`/anchor-offset classes live on the outer wrapper `<div>`, never
routed through `Helpers.classes/3` — same reasoning as `Badge`'s wrapping
`<span>`: it's positioning plumbing the popover can't function without,
not visual skin. Only the inner surface (background, elevation, rounded
corners, cosmetic padding/min-width) is paperize-gated.

**The trigger is a `pp_icon_button` or a `pp_button`** (since 0.4.0):
`trigger_icon` + `trigger_label` give an icon button, otherwise the
`:trigger` slot is a button label; `trigger_variant`/`trigger_color`/
`trigger_class` pass through, and `trigger_variant="none"` keeps a bare
button. Items are `pp_menu_item/1` (MD3's 48dp row with leading icon,
supporting/trailing text and the Expressive selected color); the panel is
the Expressive menu surface (`surface-container`, `lg` corners, 4dp
padding, or `tertiary-container` for `color="vibrant"`). `SplitButton`
reuses `Menu.toggle/2`/`close/2` and the same panel classes. The
wiring (`id="<id>-trigger"`, `aria-haspopup`/`aria-expanded`/
`aria-controls`, `phx-click={toggle(id)}`) goes through `pp_button`'s
global `rest`. Headless-Chromium note: `JS.toggle` applies `display` in a
`requestAnimationFrame`, which `--dump-dom` never runs, so the panel
reads `display: none` there even though a `--screenshot` of the same page
shows it open; check `aria-expanded` (set synchronously) or screenshot.

`anchor` (`bottom-start`/`bottom-end`/`top-start`/`top-end`, default
`bottom-start`) is where the panel opens. CSS alone can't detect viewport
collisions, so flipping is the JS hook's job (see "The JS hook"): it
measures the open panel and sets `data-pp-flip`. Without an `id` (no
hook) the anchor is fixed, as `Tooltip`'s `placement` is.

## Selection: `Slider` (MD3 slider, Expressive sizes)

The native range input draws only the **handle** (MD3's 4dp bar, 2dp
while pressed): its own track is transparent. The visible track is a
separate element behind it, painted by **one gradient** from custom
properties on the wrapper (`--pp-slider-f`, or `-lo`/`-hi` for range
sliders) that the server sets for first paint and a small inline
`oninput` snippet updates. A handle's center is `2px + (100% - 4px) * f`,
since the native thumb travels the width minus its own width. The
gradient leaves MD3's 6dp gap on each side of each handle, and a dot
layer draws the stop indicator.

One code path covers single sliders, range sliders (two stacked inputs
whose thumbs alone take the pointer), `track="inverted"`, and
Expressive's `centered` track (CSS `min()`/`max()` pick the side, and CSS
clamps backwards gradient stops, which collapses the unused segment).
Geometry is one utility (`pp-slider-track-shape`); each mode is a
separate utility that only sets `background`. The stop-dot layers are
`var()` fallbacks, so `pp-slider-no-stop` blanks them without competing
with the mode's own `background`. The rule from earlier versions still
holds: **no two utilities on one element may set the same property**,
because their stylesheet order isn't ours to control.

Sizes are custom properties (`--pp-slider-track-size`/`-handle`/`-radius`)
set by literal classes, and so are colors (`--pp-slider-active`/
`-inactive`). The Expressive value indicator is a bubble positioned with
the same `calc()` off the same variable, shown via
`group-has-[:active]/slider:`. No hook needed.

Vertical sliders use `writing-mode: vertical-lr` (+ Firefox's
`-moz-orient`) with a complete, separate input utility. Range and vertical
can't be combined.

## Text inputs: `TextField` (MD3 text field)

`TextField.pp_text_field/1` is MD3's text field: `outlined` (default) and
`filled` (MD3 has no `standard`), 56dp, `body-large` text, the label
floating to `body-small` — **onto the border** for outlined, to the top
of the box for filled. `color` (`primary`/`secondary`/`tertiary`/`error`)
shows on `:focus-within`. Filled's active indicator is an inset bottom
shadow (1dp → 2dp on focus without moving anything). Errors add a
trailing error icon; `multiline` and the `:start_adornment`/
`:end_adornment` slots (MD3's leading/trailing icons, prefix/suffix
text) round it out. There's one size (MD3's 56dp) and the label is
always there (0.5.0 removed `size="small"` and `hide_label`).

The floating label is the same pure-CSS `peer-*` trick as `Checkbox`/
`Switch`'s state styling (see "CSS-only interactive state" above): the
`<input>`/`<textarea>` is marked `peer` and always rendered with
`placeholder=" "` (a single space, never empty — an empty placeholder
doesn't trigger `:placeholder-shown` in the same reliable way across
browsers), and the label uses `peer-[:not(:placeholder-shown)]:` /
`peer-focus:` to float up. This is *why* adornments had to be added as flex
siblings of the whole `<input>`/`<label>` pair (wrapped together in their
own `relative` div) rather than inside it: `peer-*` only reaches DOM
*siblings* of the marked element, so the input and its label must stay flat
siblings of each other no matter what else the wrapper contains — an
adornment `<span>` sitting between them would have broken every
`peer-focus:`/`peer-[...]:` selector on the label.

`multiline` swaps in a `<textarea rows={@rows}>` for the `<input>` but reuses
every other class/mechanism unchanged — `:placeholder-shown`/`:focus` work
identically on both element types, so the label doesn't need to know or care
which one it's paired with. One easy-to-miss HEEx gotcha here: the textarea's value must be written as
`<textarea ...>{@value}</textarea>` with **zero whitespace** between the
opening tag's `>` and `{@value}` — a newline there gets preserved as a
leading blank line in every browser's rendering of `<textarea>` content.

`color`'s effect is invisible in a plain (unfocused) screenshot since it's
entirely a `:focus-within` style — this was verified by simulating a real
DOM focus via Chrome DevTools Protocol (`element.focus()` + read
`getComputedStyle`) rather than trusting a static render, the same rigor
applied to any state that only exists on `:hover`/`:focus`/`:active`.

`variant="outlined"`'s border has a real notch cut into it around the
floated label (MD3's outlined field notch) via an actual `<fieldset>`/
`<legend>` — not a CSS trick, a genuine browser behavior: a `<fieldset>`
natively draws a gap in its own border around an in-flow `<legend>`, no
custom CSS needed for the gap itself, just color/rounding on top. An
earlier version skipped this (label just floating on an unbroken border
line), which read as visibly off next to a real Material text field — a
side-by-side screenshot comparison caught what unit tests alone didn't,
since "the label is at the right position" and "the border has a
recognizable Material notch" are different, both-look-plausible-in-
isolation claims. The `<fieldset>` is a *sibling* of the input (not an
ancestor — it can't double as the actual flex row arranging adornments/
input/label, because giving it `display: flex` breaks the native
legend-notching behavior entirely, confirmed empirically before
committing to the approach), so connecting "the input has focus/content"
to "open the legend's notch" can't use `peer-*` (which needs true
siblings) — it uses `has-*` from their common ancestor instead, and it
has to be scoped to the real tag
(`has-[input:not(:placeholder-shown)]`/`has-[textarea:not(:placeholder-shown)]`).
The unscoped `has-[:not(:placeholder-shown)]` looks equivalent but isn't:
it also matches the plain `<label>` sitting in the same wrapper (which
vacuously satisfies "not placeholder-shown," the same way any element
that isn't a form control does), so the notch would stay permanently
open regardless of the input's actual state — caught by working through
what the selector matches before shipping it, not from a failing test.

**Follow-up bug, caught from a user screenshot of the supposedly-closed
state**: the legend's `px-1` was originally unconditional, which left a
small permanent gap in the resting (unfocused, empty) border exactly the
width of that padding. Real CSS box-model rule, not a framework quirk:
`max-width` can shrink an element's content toward nothing, but it can
never shrink the element below its own `padding` — a padded box has a
hard floor at `padding-left + padding-right` regardless of how small
`max-width` is set. Fixed by making `px-1` conditional, applied by the
exact same `has-[input:not(:placeholder-shown)]`/`focus-within` triggers
that open `max-width`, so the resting legend has **zero** padding (a true
zero-width box, not just visually small) and the border stays completely
unbroken until the notch actually needs to open.

**Second follow-up, caught from a user screenshot in 0.5.2**: every
raised outlined label sat 8px *above* the border, and every outlined box
looked 48px tall instead of 56. A fieldset draws its top border through
the vertical middle of its `<legend>`, and the legend is 16px tall
(`body-small`), so with the fieldset at `inset-0` the drawn border ran
8px below the box's top edge — while the label is positioned against the
box. The fieldset now starts 8px higher (`inset-x-0 bottom-0 -top-2`,
half the legend), putting the line on the box edge. `Select` had the same
fieldset and the same fix. Measured with `getBoundingClientRect` in
Chromium against the compiled CSS (the border's y is the fieldset's top
plus half the legend's height): raised labels now center exactly on the
line, resting labels on the 56px box's middle.

The same pass fixed the notch with a leading prefix: it used to be cut at
a fixed `ms-12` (sized for a 24dp icon), so a `$` prefix put the label at
x=38 and the notch at x=49. Now the label's containing block is the
field box (the input's wrapper isn't `relative`) and its `start` is
`auto` at rest — so it sits at its *static* position, after whatever
leads the input, plus `ms-4` — and raised in an outlined field it takes
`start-0`: 16dp from the edge, MD3's placement for a populated outlined
field with a leading icon, which is exactly where the (now fixed) notch
is. A raised filled label keeps its static position, aligned with the
input text, as MD3 places it. `start` going from `auto` to `0` doesn't
animate, so with a leading icon the label moves sideways in one step as
it rises; without one, the static position already is the edge, so
nothing jumps. Headless note: focus state needs
`Emulation.setFocusEmulationEnabled` over the DevTools protocol — without
it the page has no focus, `:focus` never matches, and a focused field
looks unfocused.

## Communication: `Badge`, `Chip`, `Tooltip`, and `Avatar`

- **`Badge`** is MD3's two badges: no `content` gives the 6dp small
  badge, `content` the 16dp large one (`label-small`, integers above
  `max`, default 999, shown as `999+`). Always `error`/`on-error`, on the
  child's top-end corner; a count of `0` hides it. The wrapping `<span>`'s
  `relative inline-flex shrink-0` is a hardcoded literal, not gated by
  `paperize`: it's positioning plumbing the badge can't work without, not
  skin.

- **`Chip`** is MD3's four kinds (`assist`, `filter`, `input`,
  `suggestion`). All but non-clickable input chips are `<button>`s;
  filter chips are toggles using the toggle-button mechanism
  (`aria-pressed`, `PhoenixPaper.Toggle`). The remove control
  (`deletable`) is deliberately a `<span role="button" tabindex="0">`, not
  a `<button>`: nesting a `<button>` inside a clickable chip's `<button>`
  is invalid HTML (the browser auto-closes the outer one). A tiny
  `onkeydown` snippet makes it keyboard-operable. It does **not** call
  `stopPropagation()`: LiveView's `phx-click` is one delegated
  window-level listener, so stopping propagation broke `on_delete`
  entirely (found with a real click), and LiveView already resolves a
  click to the nearest `phx-click`.

- **`Avatar`** is MD3's list leading element: one 40dp circle in
  `primary-container` with `title-medium` initials (or an icon) in
  `on-primary-container`, and an optional `<img>` over it. The fallback
  is always rendered underneath; a tiny inline `onerror` hides a broken
  image. 0.4's `size`/`variant`/`color` didn't come back (MD3 fixes all
  three).

- **`Tooltip`** is pure CSS: a named `group/tooltip` wrapper with
  `group-hover/tooltip:`/`group-focus-within/tooltip:` (named so an outer
  `group` can't trigger it). MD3's `plain` (`inverse-surface`) and `rich`
  (`surface-container` with subhead and actions, kept open while hovered
  because the gap to the trigger is padding, not margin) variants. Showing
  waits `delay-300`, hiding is immediate. No arrow (MD3 has none).
  Viewport flipping is the JS hook's (tooltips need an `id` for it).

  **A verification dead-end worth knowing about, so it isn't re-walked**:
  headless Chromium's `--virtual-time-budget` fast-forwards timers but
  doesn't reliably drive the compositor frames a CSS *transition* needs,
  so a transitioning property (the tooltip's opacity) can read "stuck" at
  its start value (`element.getAnimations()` shows the transition
  `"running"` forever). If a headless check of any transitioning property
  comes back stuck, suspect the test methodology before the component.

## Communication and containment: `Dialog`, sheets, `Progress`, `LoadingIndicator`, `Snackbar`

- `Dialog` is MD3's basic dialog (28dp, `surface-container-high`, hero
  `icon`, 280–560dp wide) plus `fullscreen`/`responsive` variants.
- `Progress` follows the 2024 MD3 spec: indicator/track gap, stop dot, and
  Expressive `wavy` (a box masked by a repeating SVG wave tile whose
  `mask-position` slides) and `thickness`.
- `LoadingIndicator` morphs a 72-point polygon through seven MD3 shapes
  with CSS `d: path()` keyframes, generated offline from polar functions.
  The hook carries the same functions for Safari.
- `BottomSheet`/`SideSheet` reuse `Dialog`'s exact mechanism.
- `Snackbar` is always `inverse-surface`, at the bottom of the viewport
  (centered on compact screens, bottom-start from `sm`), entering with
  MD3's fade-and-expand.

**`Dialog` uses the generated modal's mechanism.** It needs client-side
show/hide with transitions, scrim click-to-close, Escape-to-close, and
focus trapping — none of which need a server round-trip — so it uses what
`mix phx.new`'s generated `core_components.ex` modal uses: always rendered
(hidden via CSS), `Phoenix.LiveView.JS` commands
(`JS.show`/`JS.hide`/`JS.exec`/`JS.focus_first`/`JS.pop_focus`) for the
transitions, and `Phoenix.Component.focus_wrap/1` (backed by the
`Phoenix.FocusWrap` hook that ships with `phoenix_live_view.js`) for
tab-focus trapping. The width goes on the **focus-wrap container**, not
the panel: the `flex items-center justify-center` row sizes its direct
child, the container, so with the width on the panel a canvas or other
no-natural-width child collapsed the dialog and long text pushed it
off-centre. The container is `w-full max-w-[560px]` (paperize-gated) and
the panel is plain `w-full`. The one non-obvious wiring detail:
`data-cancel` has to live on the *outermost* element (the one
`JS.exec("data-cancel", to: "##{id}")` targets by CSS selector), not on
the inner content — on the wrong element, `JS.exec` finds nothing and
Escape/scrim-click silently do nothing.

**`show/2` must undo everything `hide/2` does.** `hide/2` fades out the
wrapper, the panel *and* the scrim (`#<id>-backdrop`); until 0.5.2,
`show/2` only brought back the first two, so from the second open on the
scrim stayed `display: none` (the first open looked fine because the
scrim had never been hidden yet). A unit test in `sheets_test.exs` now
asserts that every target `hide/2` hides appears in `show/2`, for all
three modals. It was confirmed in headless Chromium with the real
LiveView client (opening, closing and reopening each modal, reading the
scrim's computed `display`): the old code shows `none` on the second
open, the fixed code `block` every time. When adding an element a modal
hides, add it to `show/2` in the same change.

`Progress`'s circular variant is real SVG (`stroke-dasharray`/
`stroke-dashoffset` computed from `value`, with MD3's gap between
indicator and track worked out in Elixir); the indeterminate ring is the
same SVG circle with a rotating, growing/shrinking dash
(`pp-circular-rotate`/`pp-circular-dash`), and the wavy ring is a path
precomputed at compile time.

`Snackbar`'s entrance is a one-shot `@keyframes` utility
(`pp-snackbar-enter`); there's no exit animation or queue (each would need
the `Dialog`-style always-rendered machinery or state a stateless function
component has nowhere to hold). `auto_hide_duration` (ms), paired with
`on_close` (MD3's close icon button), is hook-free: a zero-size `<span
class="pp-snackbar-timeout">` inside the snackbar runs a no-op CSS
animation of `var(--pp-snackbar-timeout)` duration, and its
`onanimationend` clicks the close button. It's a *child* span, never the
root, so its `animation` can't clash with the root's entrance. Off by
default — the server usually owns "is this message live"
(`Process.send_after/3` clearing the `open` assign); the client timer is
for the no-round-trip case, i.e. `pp_flash_group`.

`positioned` (default `true`) was split out of the all-or-nothing
`paperize` gate: `positioned={false}` drops only the `fixed` placement,
keeping the container/elevation/entrance. That's what lets
`PhoenixPaper.Flash` stack several snackbars inside its own `fixed`
container instead of each one anchoring itself to the same spot.

## Communication: `PhoenixPaper.Flash` (Phoenix flash → snackbars)

`pp_flash_group/1` is the Material counterpart of a generated
`core_components.ex`'s `flash_group/1` — drop it once in the root layout.
It reads `:info`/`:error` (or whatever `kinds` lists) from `@flash` via
`Phoenix.Flash.get/2` and renders one `pp_snackbar positioned={false}` per
present message inside a `fixed` bottom stack (`flex flex-col gap-2`).

- **Dismiss needs no LiveView handler.** The close button is
  `JS.push("lv:clear-flash", value: %{key: kind})` — `lv:clear-flash` is
  handled by the LiveView JS client itself: it clears that flash key and
  the server re-renders without it, so the `:if={@message}` on the
  snackbar goes false and it's gone. `auto_hide_duration` threads straight
  through to each snackbar and fires the *same* push on the timer.
- **Text-only, by spec.** MD3 snackbars have no icon and no per-severity
  color, so the kind only sets `role` (`alert` for `:error`, `status`
  otherwise).
- **`connection_notices`** renders the client-error/server-error
  "connection lost" messages a generated `core_components` shows. They're
  a *different* mechanism from flash (no server flash entry — the server
  is what's unreachable): two `pp_snackbar`s rendered `hidden`, with
  `phx-disconnected` running
  `JS.remove_attribute("hidden", to: ".phx-client-error #pp-flash-client-error")`
  (resp. `phx-server-error`) and `phx-connected` putting `hidden` back.
  Plain attribute toggling, not `JS.show`/`JS.hide`: `JS.show` sets an
  inline `display: block`, which would override the snackbar's own `flex`.
  Tailwind's preflight makes `[hidden]` `display: none !important`, so
  `hidden` wins over the `flex` class while it's set.

The stack container is `pointer-events-none` with
`[&_[data-pp-component=snackbar]]:pointer-events-auto` so the transparent
gaps between/around snackbars don't eat clicks on the page beneath.

## Actions: toggle buttons and button groups (replace `ToggleButton`)

Expressive toggle buttons are `pp_button`/`pp_icon_button` with
`selected` (and filter chips likewise). Two modes, one class set (see
"Material Design 3 foundations"):

- **Controlled**: `selected={@bold}` renders `aria-pressed`; a click only
  fires the caller's `phx-click`.
- **Client-side**: `toggle` flips `aria-pressed` with
  `JS.toggle_attribute`; `group="name"` makes it exclusive (un-press
  `[data-pp-toggle-group="name"]`, press self). It's built by
  `PhoenixPaper.Toggle.js/2`, public `@doc false`-free, and the tests
  pattern-match its ops. JS commands rather than `onclick` because
  LiveView keeps JS-command attributes across patches.

A selected toggle also swaps shape (round ↔ square) through
`aria-pressed:rounded-*`; pressing squeezes the corners
(`active:rounded-*`, and `aria-pressed:active:` while selected), all on
`pp-motion-spatial-fast`.

`pp_button_group/1` is layout plus shape. A **connected** group sets the
corner longhands of its children in one hand-ordered `@utility`, with
specificity chosen to beat the children's own `rounded-*` (0,1,0) but
lose to their pressed/selected variants where that's intended (see the
comment in `phoenix_paper.css`). The size must be passed to both group
and buttons, since HEEx can't push attrs into children.

## Actions: `PhoenixPaper.FabMenu` (replaces `SpeedDial`)

MD3 retired the speed dial for the Expressive FAB menu. `pp_fab_menu/1`
keeps the CSS-only checkbox mechanism: a hidden checkbox, the FAB as its
`<label>`, and the item list as a later sibling reacting with
`peer-checked:`. It drops SpeedDial's hover/focus reveal (MD3 opens it on
tap) and adds:

- **Click-away**: a transparent full-screen `<label>` for the same
  checkbox, shown only while open, under the menu.
- **Escape**: a two-line inline `onkeydown` on the root.
- **The morph**: the FAB becomes a 56dp round `primary` close button
  (icons cross-rotate), and items rise with a staggered
  `transition-delay` (literal `delay-[30ms]`… classes per index).

The items are tonal pills in the FAB's color family.

## Theming

Colors are Tailwind v4 theme tokens backed by CSS custom properties in
`priv/static/phoenix_paper.css` (`@theme static`, so every role is emitted
even if no utility uses it): the MD3 role set listed under "Material
Design 3 foundations". The third brand role is `tertiary`, MD3's name. It
was `accent` from 0.2 to 0.3, and 0.4.0 renamed it back.

- **Namespaced `pp-` on every token**, because daisyUI defines its own
  `primary`/`secondary`/`base-100`/... Never add an unprefixed token.
- Dark mode keys off `[data-theme="dark"]` (daisyUI's and Phoenix 1.8's
  attribute). With no `data-theme`, a `prefers-color-scheme: dark` block
  mirrors the dark values; an explicit `data-theme="light"` wins.
  Both dark blocks also set `color-scheme: dark`.
- **Only one scheme ships**: the MD3 baseline (seed `#6750A4`). Don't add
  bundled palettes.
- **Custom themes**: `mix phoenix_paper.gen.theme --seed "#hex"`
  (`PhoenixPaper.Theme`, on a port of material-color-utilities' HCT in
  `PhoenixPaper.Theme.Hct`) writes `--color-pp-*` overrides for light,
  dark and the media-query block; or export from Material Theme Builder
  and paste. The HCT port is checked against the library's published
  reference values (red/green/blue) and Theme Builder's tonal-spot output
  for the baseline seed; keep those tests green if you touch it.
  No build step. The same goes for `--font-pp-brand`/`--font-pp-plain`
  and `--radius-pp-*`.

## `PhoenixPaper.ThemeToggle`

A System / Light / Dark segmented control (MD3's selected-segment
`secondary-container` indicator on the spatial spring). System *removes*
`data-theme`, so the `prefers-color-scheme` block follows the OS; Light
and Dark set it.

- **Its selected state is CSS keyed off the ancestor's `data-theme`**
  (`[[data-theme=dark]_&]:translate-x-16` on the indicator and the
  matching button colors), never state stored on the component. So
  there's nothing for a LiveView patch to reset, no cross-instance sync
  script, and System is simply "neither light nor dark matched". The
  trade-off: it reads the *nearest* `data-theme` ancestor, so a scoped
  `target` only shows correctly when the toggle sits inside that target.
- **No `aria-pressed`**, for the same reason: it would have to be set by
  JS on click and a patch can undo it. Each button has `aria-label`/`title`
  instead.
- **Persistence** writes `localStorage["phx:theme"]` (removed for System)
  only when `target="html"` — the exact key and semantics of Phoenix 1.8's
  generated root layout script, so a 1.8 app restores it on reload with no
  setup; the moduledoc has a four-line `<head>` snippet for other apps.
- **Why not a switch.** 0.4 also had `variant="switch"`, a sun/moon
  switch. 0.5.0 removed it: its colors were hand-picked (amber, slate,
  white) rather than MD3 roles, and its checkbox state could disagree
  with `data-theme` after a reload or a hydration patch — the lesson
  being that client-side state a stateless component renders from server
  assigns must live in an attribute LiveView won't reset (`data-theme` on
  an ancestor here), not in a form control's property.
- Verified in headless Chromium by clicking each button: `data-theme`
  removed/`light`/`dark`, `localStorage` matching, and two toggles on the
  page moving their indicators together (`translate` 0 / 32px / 64px —
  note Tailwind v4's `translate-x-*` sets the standalone `translate`
  property, so `getComputedStyle(...).transform` reads `none`; read
  `.translate`).

## Elevation

`PhoenixPaper.Elevation.class/1` maps a level to `pp-elevation-0..5`
(MD3's 0, 1, 3, 6, 8, 12dp; clamped), and `hover_class/1` to its
`hover:` twin, both as literal strings. The shadows are MD3's two-layer
values built from `--color-pp-shadow`. Elevation is a supporting cue: a
component picks its surface-container color first and adds a shadow only
where MD3 does. There's no dark-mode overlay any more (0.3's
`pp-surface-overlay`): MD3 dark surfaces are tonal colors.

## Shape (border radius)

`PhoenixPaper.Shape.class/1,2` maps a token (`:none`, `:xs`, `:sm`,
`:md`, `:lg`, `:lg_increased`, `:xl`, `:xl_increased`, `:xxl`, `:full`)
to a literal `rounded-pp-*` class backed by `--radius-pp-*`, optionally
on one edge (`:top`, `:bottom`, `:start`, `:end`). `Shape.tokens/0` is
the list for an attr's `values:`. Components with a fixed MD3 shape use
the token's class directly. Expressive buttons don't use `Shape`: their shape is
`round`/`square`, with explicit pixel radii so the morph can animate.

## Icons

PhoenixPaper does **not** bundle an icon set or an icon hex dependency. Every
`mix phx.new`-generated Phoenix app (1.7+) already vendors heroicons and
wires a Tailwind plugin that turns `hero-*` classes into CSS-mask icons —
reuse that instead of duplicating it. `PhoenixPaper.Icon.pp_icon/1` is a
thin wrapper: `<.pp_icon name="hero-check" />` just renders
`<span class="hero-check ..." />`. Any component that needs an icon
internally (a button's leading icon, a checkbox's checkmark) should accept
a `hero-*` class string the same way, not draw its own SVG.

## Consumer setup (what a project adding this dependency must do)

1. Add `{:phoenix_paper, "~> 0.5"}` to `mix.exs` (it needs
   `phoenix_live_view ~> 1.1`).
2. In `lib/my_app_web.ex`, add `use PhoenixPaper.Components` to the
   `html_helpers` quote block, next to the existing `core_components` import.
3. In `assets/css/app.css`, after `@import "tailwindcss";`, add:
   ```css
   @import "../../deps/phoenix_paper/priv/static/phoenix_paper.css";
   ```
   No `@source` line is needed: `phoenix_paper.css` declares its own
   `@source "../../lib";`, resolved relative to itself. Don't remove it.
4. Load Roboto Flex (or override `--font-pp-brand`/`--font-pp-plain`).
5. Register the hook: `import PhoenixPaperHooks from "phoenix_paper"`,
   spread into the LiveSocket's `hooks`.

## HEEx gotcha: literal `{`/`}` in attribute strings and text

A literal `{...}` inside a HEEx double-quoted attribute value (e.g.
`label="paperize={false} demo"`) or text node is parsed as an **embedded
Elixir expression**, not literal text — it silently corrupts that render
(and can cascade into sibling markup) instead of raising. This bit an
earlier version of this library's own demo copy once. When writing any
string literal a component (or its tests/docs examples) renders, avoid
literal `{`/`}` characters entirely (write `paperize: false`, not
`paperize={false}`).

## More HEEx gotchas: nested heredocs, and `<`/escaped `"` in plain string attrs

Two more ways to corrupt a `~H"""..."""` template without a compile error
that points at the real cause, both hit while building a (since-removed) live-preview catalog:

- **A `~S"""..."""` (or any other triple-quoted heredoc/sigil) written
  directly inside a `~H"""..."""` collides with it.** Elixir's tokenizer
  scans for the *outer* heredoc's closing `"""` at the raw character level —
  it has no idea it's inside a sigil versus plain code, so the first `"""`
  it finds (the nested sigil's own opening or closing delimiter) can get
  mistaken for the outer one, breaking heredoc matching for everything
  after it. Fix: pull the nested content into its own top-level module
  attribute (`@some_code ~S"""..."""`, defined outside any `~H` block) and
  reference it inside the template as `{@some_code}` — a plain variable,
  no nesting.
- **A literal `<tag>` or an escaped `word=\"value\"` sequence inside a
  plain (non-`{}`-wrapped) HEEx attribute string breaks the tokenizer too**
  — e.g. `description="...tag=\"span\"..."` fails with "invalid character
  in attribute name" even though there's no `<` anywhere near it. The
  tokenizer's attribute-value scanner isn't a full string-aware parser; it
  reads `<` as tag-start and `identifier="` as attribute-start regardless
  of the surrounding quotes. This does **not** affect strings inside a
  `{...}`-wrapped attribute value (e.g. `props={[{"key", "a <select>
  element"}]}`) — that switches to full Elixir-expression parsing, which
  handles escaped quotes normally. Fix: avoid literal `<...>` and escaped
  `\"...\"` in plain string attributes; rephrase in prose, use single
  quotes for a "quoted" term, or move the string into a `{}`-wrapped
  expression/module attribute instead.

Two more, hit writing `Badge`/`Chip`'s moduledocs and `Chip`'s `on_delete`
doc string — plain Elixir gotchas, not HEEx-specific, but easy to trip
into while writing the kind of prose-with-code-samples moduledoc this
library favors:

- **A literal `#{...}`-shaped substring inside a plain `@moduledoc
  """..."""` heredoc is real string interpolation**, not literal text —
  `` `"#{max}+"` `` in prose describing `Badge`'s `max` behavior tried to
  interpolate a variable named `max` that doesn't exist at the module
  level, failing to compile with `undefined variable "max"`. Fix: escape
  the `#` as `\#` (`` `"\#{max}+"` ``) whenever a moduledoc's prose needs to
  show literal `#{...}` syntax.
- **`~s(...)`/`~S(...)` do not support nested, unescaped parens** — unlike
  `"..."` strings, sigils using paired bracket delimiters (`()`, `[]`,
  `{}`) only track delimiter *depth* naively; `~s(call("x"))` fails with
  "unexpected token: )" because the tokenizer isn't aware the inner `)`
  belongs to a string literal, not sigil-closing. Confirmed directly:
  `~s(a (b) c)` fails the same way with no strings involved at all — it's
  a pure paren-counting issue, nothing to do with quotes specifically. Fix:
  pick a sigil delimiter that doesn't appear in the content (`~s[...]` for
  content containing parens, as `Chip`'s `on_delete` doc does for its
  `JS.push("remove_chip")` example), rather than trying to escape the
  inner parens.

## Major gotcha: `assign_new/3` does nothing for an attr that already has a `default`

Found while reworking `Slider` — `PhoenixPaper.Slider`'s own new `value`
handling raised `MatchError` on a plain `<.pp_slider name="x" />` with no
`value` passed, which led to discovering the **same bug already shipping**
in every other form component's `field=` clause (`TextField`, then
called `Input`, `Checkbox`, `Switch`, `RadioGroup`, `Select`, and two
components since removed): `field=` never
actually populated `name`/`id`/`value`/`checked` from the
`Phoenix.HTML.FormField`. Confirmed by rendering `<.pp_input field={@form[:email]} />`
directly and finding the output `<input>` had no `id`, `name`, or `value`
attribute at all — not a hypothetical, an actual broken render. Zero
existing tests caught it because not one of those components' test
files exercised the `field=` code path at all (all now do, and all now
pass — see below).

**The mechanism**: every affected attr (`value`, `name`, `id`, `checked`)
is declared with `attr(..., default: nil)` (or `default: false`).
Phoenix's `attr` macro fills in that default
value in the compiled `assigns` map at the call site *before* the
component function ever runs — so by the time the field-handling clause
executes `assign_new(:value, fn -> field.value end)`, the key `:value`
**already exists** in assigns (holding `nil`). `Phoenix.Component.assign_new/3`
only computes and sets its fallback when the key is entirely *absent*
(`case assigns do %{^key => _} -> assigns; ... end` — present-with-nil
still matches the first clause and short-circuits). So the fallback
function silently never runs, for *any* attr that also has its own
declared default — which describes essentially every optional attr in
this codebase. `assign_new/3` is the right tool for `Socket` assigns
(its original, intended use — checking whether a LiveView process has
already computed something across renders); it does not do what it looks
like it does here.

**The fix**, applied everywhere this pattern appeared: replace
`assign_new(:key, fn -> field.key end)` with
`assign(:key, assigns.key || field.key)` — plain `||`, not `assign_new`,
so it checks the actual *value* rather than key presence. For a
`:boolean` attr (`Checkbox`/`Switch`'s `checked`) use
`if(is_nil(assigns.checked), do: ..., else: assigns.checked)` instead of
bare `||`, since `false` is a legitimate, meaningful explicit value that
`checked || fallback` would wrongly discard. An attr whose default isn't
`nil` compares against that default instead.

None of these fixes can perfectly distinguish "caller explicitly passed
this exact value" from "caller didn't pass it, so the declared default
applied" — that information is genuinely gone by the time the function
body runs, a real limitation of `Phoenix.Component`'s attr system, not
something specific to this library. Treating "value equals the attr's own
declared default" as "not explicitly set" is the best available
approximation, and matches the intent every one of these callers actually
had.

**Test-coverage lesson**: every one of `TextField`/`Checkbox`/`Switch`/
`RadioGroup`/`Select`/`Slider`/`NumberField`'s test files now has
a `"field= populates name/id/value(/checked) from the form field"` test,
built via `Phoenix.Component.to_form(%{"key" => "val"}, as: :some_prefix)`
(no `Ecto.Changeset` dependency needed for a simple map-backed form). Add
one of these for any *new* form component that accepts `field=` — it's
the one test category this bug proves "looks obviously fine in the code,
and is checked nowhere" can hide behind.

## Testing

Each component gets `test/phoenix_paper/<name>_test.exs`. Render it with
`Phoenix.LiveViewTest.render_component/1,2` against a tiny private `~H`
wrapper function (see the existing tests for the pattern — this avoids
needing a live endpoint/router just to render a stateless function
component). At minimum, assert:

- The default (`paperize: true`) render includes the expected `pp-*`/
  `bg-pp-*` classes.
- `paperize={false}` does **not** include any built-in class, and does
  include the caller's `class`.

## Trying components in a real app

There is no in-repo live preview (a standalone `dev.exs` catalog script
used to exist and was removed in 0.2.3). To see a component render, add
this checkout as a `path:` dependency of a real Phoenix project:

```elixir
{:phoenix_paper, path: "../phoenix_paper"}
```

and wire it up exactly as "Consumer setup" above describes. Because
`phoenix_paper.css`'s own `@source` resolves relative to itself, the
`path:` checkout's `lib/` is scanned the same way `deps/phoenix_paper/lib`
is — the `@import` path in `app.css` is the only thing that changes.
Unit tests (below) remain the required check; the real app is for looking
at it.
