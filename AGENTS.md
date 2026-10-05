# AGENTS.md — PhoenixPaper base rules

> **Never commit, push, tag, or publish to hex.** Make the changes (code,
> docs, `CHANGELOG.md`, the `@version` bump in `mix.exs`) and leave them
> in the working tree; the maintainer reviews, commits, pushes, and runs
> `mix hex.publish` themselves.

PhoenixPaper is a **Material Design 3** component library for **Phoenix**
— including **M3 Expressive** — styled with **Tailwind CSS**. It began in
the spirit of [ember-paper](https://github.com/miguelcobain/ember-paper)
(the Ember.js Material Design addon) and moved to MD3 in 0.4.0; where MD3
specifies a component, PhoenixPaper follows the spec, and where it doesn't
(tables, pagination, autocomplete, accordion) the component borrows MUI's
API and is styled from MD3 tokens. It ships as a
hex package (a component library, not a Phoenix app) that a Phoenix project
adds as a dependency.

This file is the ground truth for how the library is built. Read it before
adding or changing a component.

## Project shape

- `lib/phoenix_paper/*.ex` — one module per component:
  - Actions: `Button`, `IconButton`, `ButtonGroup`, `SplitButton`, `Fab`,
    `FabMenu`.
  - Navigation: `TopAppBar`, `NavigationRail`, `NavigationBar`, `Toolbar`,
    `Tabs`/`Tab`/`TabPanel`, `Menu`, `Breadcrumbs`, `Pagination`.
  - Inputs: `TextField`, `Select`, `Checkbox`, `Switch`, `RadioGroup`,
    `Slider`, `NumberField`, `Rating`, `Chip`, `SearchBar`, `Form`, and the
    LiveComponents `Autocomplete`, `PowerSelect`, `TransferList`,
    `DatePicker`, `TimePicker`.
  - Containment: `Paper`, `Card`, `Dialog`, `BottomSheet`, `SideSheet`,
    `Accordion` (+ `AccordionSummary`/`Details`/`Actions`), `Collapse`,
    `Carousel`, `List`/`ListItem`/`ListSubheader`, `Divider`, the Table
    family, `ImageList`/`ImageListItem`.
  - Communication: `Badge`, `Progress`, `LoadingIndicator`, `Snackbar`,
    `Flash`, `Tooltip`, `Alert`, `Backdrop`, `Skeleton`.
  - Other: `Avatar`, `Icon`, `Typography`, `ThemeToggle`, and the layout
    primitives `Box`, `Container`, `Stack`, `Grid`, `GridItem`.

  Helpers: `Helpers`, `Elevation`, `Shape`, `Spacing`, `Ripple`, `Toggle`.
- `lib/phoenix_paper/components.ex` — `use PhoenixPaper.Components` imports
  every component's render function at once.
- `priv/static/phoenix_paper.css` — the MD3 token layer (color roles, type
  scale, shape, elevation, state layers, motion) plus the component
  utilities that are too much for class strings (slider, progress,
  loading indicator, button groups, carousel, ...). Consumers `@import` it.
- `priv/static/phoenix_paper.js` + `package.json` — the **optional**
  LiveView hook (see "The optional JS hook" below).
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
  `inverse-primary`; the fixed roles; `scrim`, `shadow`. Plus the
  PhoenixPaper extension roles `success`/`warning`/`info` (same shape as
  `error`). Pick the role the MD3 spec names for the component (cards
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

## The optional JS hook

PhoenixPaper's rule used to be "no JS hooks". Since 0.4.0 it is: **every
component works without JavaScript beyond Phoenix's own, and one optional
hook enhances what CSS can't do (everywhere).** `priv/static/phoenix_paper.js`
exports one LiveView hook, `PhoenixPaper`, that dispatches on what it's
mounted on (tabs' sliding indicator, top app bar scroll state, loading
indicator morph, bottom-sheet drag, carousel mask, time-picker dial drag,
and edge flipping for menus, submenus and tooltips). Edge flipping sets
`data-pp-flip` through `hook.js()` (so patches keep it) and is styled by
**unlayered** rules at the end of `phoenix_paper.css`, which beat
Tailwind's layered utilities without `!important`. Components render
`phx-hook={Helpers.hook(id)}`, which is `nil` unless the app set
`config :phoenix_paper, hook: true` (read at render time) *and* an id is
available, so apps that don't register the hook never get LiveView's
"unknown hook" error.

When adding hook behavior: the CSS-only version must still work and be
the documented default; put the hook on an element that doesn't already
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
  - `paperize` (`:boolean`, default `true`) — see the contract below. The
    one exception is `PhoenixPaper.Box`, which has no `paperize` attr at
    all: it's a bare layout primitive with no default visual style to
    strip, so the attr would be a no-op. If a new component genuinely
    never applies any built-in classes, drop `paperize` rather than ship a
    no-op flag — but that should be rare; almost everything has *some*
    skin (even `Stack`/`Grid`/`Container` apply layout classes that
    `paperize={false}` legitimately turns off).
  - `class` (`:any`, default `nil`) — concatenated after the component's
    own built-in classes (see "Overriding built-in classes via `class`"
    below for what that does and doesn't guarantee).
  - `rest` (`:global`) — for `phx-*` bindings, `id`, `data-*`, etc.
- Register new components in `PhoenixPaper.Components`' `__using__/1` in the
  same change.
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

`Button`'s link branch (`href`/`navigate`/`patch` set → `Phoenix.Component.link/1`,
MUI's `Button` `href`/`component={Link}`) has one wrinkle `ListItem`'s
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
snippet — no JS hook, no bundler, same philosophy as `NumberField`'s
steppers. Every genuinely click-driven component (`Button`, `IconButton`, `Fab`,
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
(`Button`, `Fab`, `NumberField`'s steppers, `Autocomplete`'s option
button, `TransferList`'s move buttons) before being caught and
fixed — when adding a new component with a raw `<button>` (or `<select>`),
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
`bg-pp-primary`, `class="!size-24"` to override `Avatar`'s preset
`size-*`. `!` beats a non-`!` class regardless of stylesheet order, so it's
the one deterministic way to win. This was already the documented
workaround for the one case even `tails` itself couldn't merge (`size-*`,
a shorthand its ruleset predates — see `ThemeToggle`'s section below); it's
now the standard pattern for *every* override, not just that one case.

**Point people at the attr first.** Most of the overrides people reach
for already have an attr that *changes* the built-in class instead of
fighting it — a class conflict there isn't a bug to work around with `!`,
it's a sign the attr was missed. Found in practice: a `class="flex-col"`
on a `direction="row"` `pp_stack` silently lost to the stack's own
`flex-row`, and nothing warned. When a component emits a layout/size
class from an attr, name that attr in its moduledoc as the way to change
it (see `PhoenixPaper.Stack`'s "Use the attrs, not `class`" table). The
current set:

| Component | Built-in class | Change it with |
|-----------|----------------|----------------|
| `Stack` | `flex-col`/`flex-row`, `gap-*`, `flex-wrap` | `direction`, `spacing`, `wrap` |
| `Grid` | `gap-*` | `spacing` |
| `GridItem` | `col-span-*`, `md:col-span-*` | `span`, `md` |
| `Container` | `max-w-screen-*` | `max_width` |
| `Paper` | surface color, `pp-elevation-*`, `rounded-pp-*` | `color`, `elevation`, `shape` |
| `Card`/`Accordion`/`TableContainer` | surface, `rounded-pp-*` | `variant`, `shape` |
| `Card` | `p-*` | `padding` |
| `Button`/`IconButton` | colors, height/padding/type, corners | `variant`, `color` (incl. `inherit`), `size`, `shape`, `width` |
| `Avatar` | `size-*`, colors | `size`, `color` |
| `Icon` | `size-*` | `size` (`none` = no built-in size) |
| `Fab`/`FabMenu`/`Button`/`IconButton` | `relative` | `position` |
| `Typography` | type role, color | `variant`, `emphasized`, `color` |
| `List`/`ListItem` | `min-h-*`/`py-*`, `ps-*` | `dense`, `nested`, `inset` |

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
  `PhoenixPaper.Elevation.class/1`, `PhoenixPaper.Spacing.padding/1`, and
  `PhoenixPaper.Button`'s `color_classes/2` for the pattern.
- The same applies to variant-prefixed combinations (`hover:pp-elevation-4`)
  — the whole prefixed token must appear literally somewhere, not be
  assembled at runtime by concatenating a prefix and a helper's return
  value. `PhoenixPaper.Elevation` shows the pattern: `class/1` and its
  `hover_class/1` twin each spell out every level as a literal
  (`"pp-elevation-2"`, `"hover:pp-elevation-2"`, ...).

## CSS-only interactive state: `peer-*` vs `has-[:checked]:`

Several components (`Checkbox`, `Switch`, `RadioGroup`, `Rating`) fake a
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

When cascading a fill effect across *multiple* controls sharing one name
(`Rating`'s "hovering star 3 highlights stars 1-3"), the standard
`peer-checked:`/`peer-hover:` sibling-combinator behavior already extends
past the immediate next element to *every later sibling* — so putting a
shared `peer` class on every input/label pair, laid out flat (not nested per
item) and reversed with `flex-row-reverse`, is enough; see `Rating` for the
full pattern and why the elements must be flat siblings, not nested per-star
wrappers.

A third variant, for toggling something from *outside* its DOM subtree
entirely (the navigation rail's modal panel, opened by a menu button that
lives inside the `TopAppBar`, nowhere near the rail): a plain `<label for={checkbox_id}>`
checks a checkbox regardless of where the label sits in the document — label
targeting is id-based, not sibling-based. Only the elements that need to
*react* to the checkbox (the rail, its scrim) have to be its
actual siblings for `peer-checked:` to reach them; the button that flips it
doesn't.

`FabMenu` uses the same checkbox, plus a click-away `<label>` for it. (0.3's `SpeedDial` layered a fourth thing on top of that checkbox: the reveal
target reacts to `peer-checked:` **or** `group-hover:` **or**
`group-focus-within:` at once, so one CSS-only component opens on tap
(checkbox, sticky), hover (transient), and keyboard focus. See its own
section under "Actions" for why the trigger↔actions gap must be padding.

## Stateless function components vs. `Phoenix.LiveComponent`

Every component is a stateless `Phoenix.Component` function (`pp_*/1`) by
default — that's the whole point of the `pp_` import convention. Reach for a
`Phoenix.LiveComponent` only when a component needs interactive state a
single render pass can't express from its attrs alone (`Autocomplete`'s open
dropdown + filtered list, `PowerSelect`'s search term/results/selection,
`TransferList`'s left/right item split, `DatePicker`'s viewed month and
pending date, `TimePicker`'s dial state). Those five are the only such
components on purpose: they aren't imported by
`PhoenixPaper.Components` (there's no function to import — they're used
directly as `<.live_component module={PhoenixPaper.Autocomplete} ...} />`),
they only work inside a LiveView (not a plain dead/controller-rendered
page), and that limitation should be called out in their moduledoc. Default
to a stateless function component; justify a `LiveComponent` explicitly.

## Forms: `PowerSelect` (ember-power-select)

A `LiveComponent` modeled on ember-power-select. The server holds the
search term, the current results, the selection and a pending search; the
client does only what LiveView leaves alone when it patches. Decisions
worth knowing before touching it:

- **Open/close is `Phoenix.LiveView.JS`** (`show/1`, `hide/2`, `toggle/2`,
  `pick/5`, public `@doc false` and tested by pattern-matching their ops,
  like `Tabs.select/2`), not an `open` assign. JS-command display state
  survives patches, and a click-away doesn't cost a round trip. The list
  is always rendered, hidden.
- **Keyboard is one inline `onkeydown` on the root** (`@keyboard_js`). It
  only moves DOM focus and `.click()`s elements that already exist (options,
  chips, a hidden `data-pp-close` button running `hide/2`). Focus and
  clicks can't be undone by a patch, unlike a script mutating attributes
  (the `ThemeToggle` hydration bug). Type-ahead on a search-less trigger
  works on the hidden options the same way.
- **No `<form>` inside, and the search box is detached from the
  caller's form.** A `phx-change` needs a form, but the component usually
  sits *inside* the caller's form and a nested `<form>` is dropped by the
  HTML parser. So the search box uses `phx-keyup` (key events send the
  input's `value`) with `phx-debounce`, has no `name`, and its `form`
  attribute points at a nonexistent id. That makes `input.form` null, so
  LiveView never runs the caller's `phx-change` for it, and it's never
  submitted. `Autocomplete` had a real nested `<form>` until 0.3.0; it now
  uses the same trick.
- **The caller's form still sees changes.** Hidden inputs carry the
  value. After each change the server renders a fresh
  `<span id="<id>-changed-N" phx-mounted={JS.dispatch("input", ...)}>`:
  the id changes, so it's a new element, and `phx-mounted` fires after the
  patch, when the hidden inputs already hold the new value. The dispatched
  `input` event bubbles into the caller's form `phx-change`, like a native
  select's. `on_change` (a function, run in the LiveView process) covers
  use outside a form.
- **The parent's `value` is only re-read when it changes**
  (`external_value`). A parent re-render with a stale value must not undo
  a pick that hasn't round-tripped yet.
- **Async search is `start_async/3`.** LiveView drops results from a
  superseded task by ref, and the task also returns its term, which is
  compared with the current one. A blank term cancels and shows `options`.
- **Accent folding is NFD plus stripping `\p{Mn}`**, with a small table
  for letters that don't decompose (`ø`, `æ`, `œ`, `ß`, `ł`, `đ`, `ð`).
- **A LiveComponent has no `attr` defaults.** An omitted attr is simply
  absent, so `update/2` fills `@defaults` with `assign_new/3`. That's
  correct here, unlike in function components (see the `assign_new/3`
  gotcha below).

Verified two ways: `live_isolated/3` tests with a real host LiveView
(search, picks, clear, multiple, disabled options, async ordering, the
stale-parent case) through `PhoenixPaper.TestEndpoint` in `test/support`
(needs the test-only `lazy_html` dep). Also headless Chromium driven over
the DevTools protocol, with the real `phoenix.js`/`phoenix_live_view.js`
and a LiveSocket that never connects: open/close, click-away, arrow keys,
Escape, type-ahead, search focus, Enter not submitting, Backspace removing
a chip, the search box not being in `FormData`. Not covered in the
browser: the `phx-mounted` dispatch, which only fires after a real patch.

## Layout primitives (`Box`, `Container`, `Stack`, `Grid`/`GridItem`, `ImageList`/`ImageListItem`)

These are named after and loosely modeled on MUI's Layout category
(mui.com/material-ui) but are Tailwind-native reinterpretations, not ports —
MUI's `sx` prop is a React-specific styled-system feature with no Phoenix
equivalent, and a few things are deliberately narrower than MUI's version
because of the Tailwind class-safety rule above (every responsive/spanning
class has to be a literal, so covering MUI's full breakpoint matrix means
writing out every combination by hand). Notably: `GridItem` only supports a
`md:` breakpoint override, not MUI Grid's full `sm`/`md`/`lg`/`xl` set (see
its moduledoc for why and how to extend it), and `Stack`'s `divider` prop
isn't supported since a stateless component only gets one opaque slot, not
a list of children it could interleave dividers between. `Container`'s
`max_width` uses Tailwind's own `sm`/`md`/`lg`/`xl`/`2xl` screen scale
rather than replicating MUI's specific pixel breakpoints.

## Surfaces and composition (`Paper`, `Card`, `Typography`)

`PhoenixPaper.Paper` is the base surface primitive (background + elevation
+ shape, no padding, no slots) — `Card` is built by composing `Paper`
rather than duplicating its `paper_classes`, matching MUI's real
architecture (`Card` wraps `Paper` there too). When a new component needs
"a raised surface," reach for `<.pp_paper>` instead of hand-rolling
`bg-pp-surface` + `Elevation.class/1` + `Shape.class/1` again.

**Link attributes need a route to the `<a>`.** A linkable component whose
`rest` lands on the link itself (`Button`, `ListItem`) must list the
non-global link attrs in `attr(:rest, :global, include: ~w(target rel
download hreflang referrerpolicy method csrf_token replace))` — `target`
and `rel` aren't HTML globals, so without the `include` Phoenix rejects
them at compile time. A component whose `rest` lands on a *wrapper*
instead (`Card`: `rest` goes on the `Paper` root, the link is inside it)
needs explicit `target`/`rel` attrs forwarded to the link, or they'd end
up on a `<div>` where they do nothing. `ListItem` and `Card` were both
missing this until 0.2.6.

Composing one PhoenixPaper component inside another needs one extra step
`Card` uses: `Paper` hardcodes `data-pp-component="paper"` on its own root,
and every component is expected to mark itself with *its own* name (see
"Component conventions") — so `Paper` exposes a `component` attr (default
`"paper"`) that a wrapper overrides, e.g. `<.pp_paper component="card">`.
Don't try to override it by passing `data-pp-component="card"` through
`{@rest}` instead — `Paper`'s `<div>` already has that attribute set
literally, so the one from `rest` would just render as an ignored
duplicate rather than replacing it; only the first `data-pp-component` a
browser sees wins.

**`Card`'s link mode is a "stretched link"** (since 0.2.5). The title +
body `<a>` gets an `after:absolute after:inset-0` overlay against the
now-`relative` card root, so the whole card, actions row included, is
the click/hover/focus target, while `:actions` stays outside the `<a>`
(a button inside a link is invalid). The hover tint and focus ring are
drawn on that `::after` (`hover:after:bg-...`), not the link box. The
actions row is `relative z-10` to sit above the overlay, plus
`pointer-events-none [&>*]:pointer-events-auto` so its buttons keep their
clicks but the gaps between them fall through to the link. Verified with
`document.elementFromPoint` in Chromium: title, body and the actions-row
gap all hit the card link, and the action button hits itself. The ripple
still spawns from the link element, and its span is positioned against the
`relative` card root, which works because the link's box starts at the
root's top-left corner.

## Surfaces: `Accordion`, `AccordionSummary`, `AccordionDetails`, `AccordionActions`

Modeled on MUI's `Accordion` — pure CSS, no JS/LiveView, the same hidden-
checkbox-plus-`peer-checked:` trick as `NavigationRail`/`Rating`. `pp_accordion/1`
renders the checkbox itself, as the first child inside its own `Paper`
surface; the caller writes `AccordionSummary`/`AccordionDetails`/
`AccordionActions` as its `inner_block`, making them flat siblings *after*
the checkbox (all three need the *same* `id` as `pp_accordion/1`, to build
the matching `for=`/`peer-checked:` wiring — there's no way for sibling
components to discover a shared id implicitly).

Two things worth remembering if you touch this family:

- **`disable_gutters`'s margin needs `has-[:checked]:`, not `peer-checked:`**
  — caught this while building it, not after. Every *other* CSS reaction in
  this family targets a true sibling of the checkbox (`AccordionSummary`'s
  label, `AccordionDetails`, `AccordionActions` — all written by the caller
  *after* the checkbox in `pp_accordion/1`'s `inner_block`), so
  `peer-checked:` is correct there. But the gutters margin has to land on
  `pp_accordion/1`'s own `Paper` root — which is the checkbox's *ancestor*,
  not its sibling (the checkbox is rendered *inside* that root, as its own
  first child). `peer-checked:` only reaches later siblings of the peer, so
  it can't express "this element's own descendant checkbox is checked" —
  that needs `has-[:checked]:` instead. Same underlying CSS distinction as
  `peer-*` vs `has-[:checked]:` documented above, just easy to get backwards
  mid-refactor when three other classes in the same file correctly use
  `peer-checked:` for a *different* relationship.
- **Colors and styles live on `pp_accordion/1` only** (since 0.2.5):
  `variant` (`elevated`/`filled`/`outlined`) and `color`. The filled
  background comes from `Paper`'s new `color` attr, *not* a `bg-pp-*`
  passed through `class`: `Paper` already emits `bg-pp-surface`, and with
  no class merging the two would tie. The parts (summary/details/actions)
  have no color attr; the root reaches them with
  `[&>[data-pp-component=accordion-details]]:border-pp-on-primary/20`-style
  child selectors.
  Buttons in a filled accordion's actions need `color="inherit"`.
- **Exclusive single-panel groups are `type="radio"`, not JS/LiveView
  state.** Give every accordion in a group the same `name` and
  `pp_accordion/1` renders a radio instead of a checkbox — same-named radios
  are natively mutually exclusive, so "only one open at a time" needs zero
  extra code. Verified with real simulated clicks (not just static
  rendering) that checking one radio in the group correctly unchecks
  whichever was previously open. The one real gap versus MUI's JS-driven
  version: a checked radio can't be *unchecked* by clicking it again (an
  HTML limitation), so the group can't return to "all collapsed" — that's
  documented as a known, permanent difference, not a bug to fix.

## Surfaces: `Collapse`, and `List`'s collapsible groups

`PhoenixPaper.Collapse` (`pp_collapse/1`) is the light show/hide for when
`Accordion` is too much: one component, one `id`, a `:trigger` slot and
the content. Same hidden-checkbox-plus-`peer-checked:` mechanism as
`Accordion`/`NavigationRail`, but the content animates its height with the
`grid-template-rows: 0fr → 1fr` trick (a grid track can transition
between fractions of its content's height, which `height: auto` can't) and
toggles `invisible`/`visible` alongside it, so links inside a closed
collapse can't be tabbed to. `visibility` is in the transition list on
purpose: it flips to `hidden` only at the *end* of closing, so the content
stays painted while it shrinks.

`PhoenixPaper.List.pp_list_group/1` is the same structure with a list-item-shaped
trigger (a nested list inside a collapse, MUI's usual nested-nav pattern)
and lives in `PhoenixPaper.List` because it has no use outside a list. It
reuses `Collapse.toggle_id/1`, `content_id/1` and `content_classes/0`
instead of composing `pp_collapse/1`: the list trigger needs *different*
base classes than `Collapse`'s trigger, and with no class merging (see
above) that can't be done by passing `trigger_class`. Its trigger label
carries `data-pp-component="list-item"`, so `List`'s `dense`/`inset` and a
list-level selectors reach it like any other item.

`List`'s `dense`/`nested`/`inset` use the `Table`-style descendant
selectors (`[&_[data-pp-component=list-item]]:py-1`). `inset` targets items
*without* a leading icon via `:not(:has([data-pp-list-item-leading]))`, which
is why `ListItem`'s leading `<span>` carries that data attribute.

Headless-Chromium caveat, again: reading `visibility` right after clicking
the toggle returns the *pre*-transition value (see the `Tooltip` note
below); inject `* { transition: none !important }` before clicking when
checking the open state.

## Navigation: `TopAppBar` (renamed from `AppBar`, earlier `Navbar`)

MD3's top app bar is **surface-colored**, not primary: `bg-pp-surface`,
turning `surface-container` when content scrolls under it. The scroll
color change is CSS (`pp-top-app-bar-scroll`, an `animation-timeline:
scroll(nearest)` animation over the first 8px) where scroll-driven
animations exist; the optional hook sets `data-pp-scrolled` elsewhere,
and `scrolled` forces it from the server. Variants: `small`,
`center_aligned`, and the Expressive flexible `medium`/`large` (title on
its own row) with `subtitle`.

This removed 0.3's biggest footgun: brand-colored bars made `text`/icon
buttons inside them invisible (`text-pp-primary` on `bg-pp-primary`).
On a surface bar the default icon-button color (`on-surface-variant`) is
already right; `color="inherit"` stays the answer on colored surfaces
(the vibrant `Toolbar`, a filled card).

`max_width`/`disable_gutters` cap and centre the content row. The row's
layout classes stay unconditional under `paperize={false}` (no inner
`class` to rebuild them with) — the deliberate exception to "paperize
drops everything" that `Breadcrumbs`' `<li>`s also make.

## Navigation: stacking order

Fixed layers, MD3/MUI order: `TopAppBar`'s `sticky`/`fixed`/`absolute`
positions are `z-20`, as are a fixed `NavigationBar`/`Toolbar`; the docked
navigation rail is `md:z-30`; the modal rail's scrim `z-30` and panel
`z-40`; menus `z-40`; dialogs and sheets `z-50`. Keep new fixed/sticky
components on this ladder.

## Navigation: `NavigationRail` (replaces `Drawer`), `NavigationBar`, `Toolbar`

M3 Expressive retires the navigation drawer in favor of the expanded
navigation rail, so 0.4.0 removed `Drawer`. `pp_navigation_rail/1` keeps
the drawer's mechanism: a hidden checkbox (`data-pp-rail-toggle`), a
scrim `<label>` and the rail rendered as siblings, with
`pp_navigation_rail_toggle/1` as a `<label for>` that works from anywhere
(the top app bar). `variant="responsive"`: below `md` the checkbox opens a
modal expanded rail; from `md` the rail is docked, 96dp collapsed, and the
checkbox expands it to 280dp. `collapsed`/`expanded` are fixed.

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
inside the label's own box. Its slide from tab to tab is the optional
hook's (a FLIP animation on the spring), and is instant without it.
Verified with a unit test pattern-matching `select/2`'s exact op list,
like every JS-command component.

## Navigation: `Breadcrumbs`

The first slot in this library declared with `attr`s of its own (`slot
:item do attr :href, :any ... end`) — until now every multi-piece
component (`Table`'s rows, `ButtonGroup`'s buttons, `List`'s items) took a
plain opaque `inner_block` and left the caller to write out full child
components. `Breadcrumbs` needs to know things *about* each item (does it
have a link, in what order) to auto-insert a separator and to slice the
list for collapsing, so `:item` carries real attrs instead. Two
implementation traps worth knowing if you add another attr-carrying slot:

- **Slot attrs can't have a `:default`** (a hard compile error if you try)
  — unlike top-level `attr`, an omitted, non-required slot attr key is
  simply *absent* from the slot entry's map, not filled with `nil`. Dot
  access (`item.href`) raises `KeyError` the first time a caller omits it;
  bracket access (`item[:href]`) returns `nil` like any other `Map.get/2`
  and is the only safe way to read an optional slot attr. Verified by
  actually rendering a slot usage that omits the attr, not just reading
  the `slot/3` macro's docs — the docs say "an omitted slot will default
  to `[]`" (talking about the *slot itself* being absent), which reads
  easy to conflate with "an omitted slot *attr*" behaving the same way; it
  doesn't.
- A private function component can have several *clauses* pattern-matching
  on the shape of `assigns` directly (`defp entry(%{entry: :ellipsis} =
  assigns)`, `defp entry(%{entry: {:item, item}} = assigns)`, ...) the same
  as any other Elixir function — used here to dispatch a heterogeneous,
  server-built list (real items, `:ellipsis`, `:separator` markers,
  produced by `Enum.intersperse/2`) to different `~H` templates without a
  `case`/`cond` inside one template. Calling a `defp` component via
  `<.entry .../>` tag syntax (not just as a plain `{helper(assigns)}` call
  like `ListItem`'s `item_content/1`) works fine as long as it's in the
  same module — confirmed against `TransferList`'s own private `list/1`,
  which already did this.

Which item is "current" (rendered as plain `aria-current="page"` text
instead of a link) is **not** auto-detected by list position — same
"stateless function component, no knowledge of the current request"
reasoning `ListItem`'s `active` attr doc gives. It's simply whichever
`:item` you leave without `href`/`navigate`/`patch`, matching every one of
MUI's own docs examples (their last child is always a plain `Typography`,
never auto-computed either).

Collapsing (`max_items`, default 8, matching MUI) reuses the
hidden-checkbox-plus-`peer-checked:` trick, but unlike `Accordion`/
the navigation rail, the checkbox's `id` is generated internally with
`System.unique_integer/1` rather than taking a caller-supplied `id` attr
at all — nothing outside this component ever needs to reference it (no
sibling summary/details/actions, no external toggle button), so there's
nothing lost by not exposing one. Both the collapsed `<ol>` (first
`items_before_collapse` + ellipsis + last `items_after_collapse`) and the
full `<ol>` are always rendered, one hidden via `peer-checked:hidden`/
`peer-checked:flex` — same "always in the DOM, CSS toggles visibility"
trade-off as `Dialog`. Verified with a real simulated click on the
ellipsis `<label>` (not just a static render) that the checkbox actually
flips and the full list actually becomes visible.

Per the `paperize` contract, per-item *color* (`text-pp-primary` links,
`text-pp-outline` separator, the ellipsis control's hover styles) is
gated through `Helpers.classes/3` like everywhere else — but the `flex
items-center` layout on every `<li>` and both `<ol>`s stays unconditional
even under `paperize={false}`, the same deliberate exception `TopAppBar`'s
inner toolbar div makes and for the same reason: there's no `class` attr
exposed on an individual `<li>` for a `paperize={false}` caller to rebuild
that row layout themselves.

## Navigation: `Pagination` and `TablePagination`

Both are stateless and **1-based** (MUI's `TablePagination` is 0-based;
one numbering across the library won). Each control either links or
fires an event, never both:

- **Link mode**: a `path` function builds each URL — `page -> url` for
  `Pagination`, `(page, rows_per_page) -> url` for `TablePagination` —
  and `link` (`patch` default/`navigate`/`href`) picks the link kind. The
  page lives in the URL, so `handle_params/3` loads it. Picking a new page
  size links to page 1.
- **Event mode**: `on_change` (`Pagination`) or `on_page_change`/
  `on_rows_per_page_change` (`TablePagination`) set `phx-click`, with the
  value in `phx-value-page`/`phx-value-rows_per_page` and `target` as
  `phx-target`.

A control that can't move (previous on page 1) renders as a disabled
`<button>` in both modes, never a link to page 0. `Pagination.items/4` is
MUI's `usePagination` ellipsis algorithm, public and doctested; its
constant-length property (the bar doesn't change width while paging) has
its own test. `TablePagination`'s rows-per-page picker is a `pp_menu` of
`pp_menu_item`s rather than a native `<select>`: a `<select>` can't
navigate on change without a script or a wrapping form, and a menu item
is a plain link. That's why `TablePagination` needs an `id`, and like
`Menu` it needs the LiveView JS client on the page. Prev/next are
`pp_icon_button color="inherit"`.

## Forms: `pp_form`

`pp_form/1` is a thin layer over `Phoenix.Component.form/1`, not a
replacement: it adds a `flex flex-col` + `Spacing.gap(spacing)` column
and a right-aligned `:actions` slot, and passes everything else through
by spreading a map into `<.form>`. Only the options the caller actually
set are forwarded, because `form/1` reads `as`/`method`/`errors`/
`csrf_token` straight from its assigns and would treat a `nil` as an
explicit value. Plain `<.form>` stays fully supported; every `pp_*`
control takes `field=` either way.

## Navigation: `Menu`

MUI files `Menu`/`MenuItem` under its own "Navigation" category
(mui.com/material-ui/react-menu), so this follows the same grouping —
`pp_menu/1` is a trigger that reveals a small anchored popover list of
actions (an overflow menu, a profile menu). It's the second component in
this library that isn't stateless-and-simple (`Dialog` is the first, see
above): the checkbox/`peer-checked:` trick every other reveal component
uses (`Accordion`, `NavigationRail`, `FabMenu`) can only express "is *some*
sibling checked," with no way to close itself on an outside click or on
selecting an item — both baseline-expected menu behavior — so `Menu` uses
the same `Phoenix.LiveView.JS` + `phx-click-away` mechanism `Dialog` uses
for its own backdrop-click case, not a new mechanism.

**One real difference from `Dialog`'s architecture**: `Dialog`'s trigger
lives wherever the caller puts it on the page (`phx-click={Dialog.show(id)}`
on a button anywhere), fully decoupled from the dialog markup itself,
because a full-screen modal doesn't need to be positioned relative to
anything. A menu's popover *does* — it has to render right under its own
trigger — and doing that without a bespoke JS hook measuring
`getBoundingClientRect` (the thing this library consistently avoids, see
`Slider`'s `valueLabelDisplay`/`Tabs`'s sliding-indicator notes) means
plain CSS: `absolute`-positioning the panel against a `relative` ancestor
that also contains the trigger. So unlike `Dialog`, `pp_menu/1` renders
*both* the trigger and the panel itself, as one component, and the
`:trigger` slot only supplies the trigger's inner content, not a whole
independent element elsewhere on the page.

**Closing an item closes the menu — via bubbling, not cooperation.**
`phx-click={close(@id)}` sits on the panel wrapper itself; clicking any
item inside (a `ListItem`, a plain link, anything) runs that item's own
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
`<span>` and `Autocomplete`'s anchor `<div>` (see "The `paperize`
contract"): it's positioning plumbing the popover can't function without,
not visual skin. Only the inner `PhoenixPaper.Paper` surface (background,
elevation, rounded corners, cosmetic padding/min-width) is paperize-gated.

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
collisions, so flipping is the optional hook's job (see "The optional JS
hook"); without it the anchor is fixed — the same trade-off
`Tooltip`'s `placement` already documents and for the same reason: real
auto-flip needs a runtime viewport-space measurement, another JS hook this
library doesn't add.

## Forms: `Slider` (MD3 slider, Expressive sizes)

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

## Forms: `TextField` (renamed from `Input`; MD3 text field)

`TextField.pp_text_field/1` is MD3's text field: `outlined` (default) and
`filled` (MD3 has no `standard`), 56dp, `body-large` text, the label
floating to `body-small` — **onto the border** for outlined, to the top
of the box for filled. `color` (`primary`/`secondary`/`tertiary`/`error`)
shows on `:focus-within`. Filled's active indicator is an inset bottom
shadow (1dp → 2dp on focus without moving anything). Errors add a
trailing error icon, `size="small"` is a dense 40dp field, and
`multiline` plus the `:start_adornment`/`:end_adornment` slots work as
before. Not ported from MUI: `select` (that's the separate
`PhoenixPaper.Select` component), `fullWidth` (just put `class="w-full"` on
the caller's own wrapper — no component-level attr needed for one utility
class), `margin` (MUI's `dense`/`normal`/`none` vertical-spacing presets —
this library leaves vertical spacing between form fields to the caller's own
layout, same as everywhere else it uses `Stack`/`gap-*` rather than a
per-component margin attr), and controlled/uncontrolled value semantics
(N/A — LiveView forms already have one way to be "controlled": `field=`
from `to_form/2`).

`hide_label` (also on `Select`) *is* essentially MUI's `hiddenLabel` +
`margin="dense"` rolled together, added because the default field is
unusably tall/wide for an inline filter toolbar: it renders a **separate
`def pp_text_field(%{hide_label: true} = assigns)` clause** (cleanest — the
notch/floating-label machinery below is intricate enough that threading a
flag through every branch would be a minefield; a whole separate clause
touches none of it) that drops the outer `flex flex-col gap-1` column, the
`<label>`, the `<fieldset>` notch and the helper/error `<p>` rows, uses
`@label` as the `placeholder`, and swaps the asymmetric `pt-7 pb-2`
padding (which only exists to reserve room for the floated label) for a
symmetric `py-2.5`/`py-1.5`. Errors still show — as the red border — just
not the message text, so an error appearing doesn't reflow the toolbar
row. `outlined`'s border thickens on focus the `Select`-wrapper way
(`border` → `focus-within:border-2`), accepting the 1px shift rather than
carrying the fieldset overlay into the dense path. The `field=` clause
runs first and re-dispatches, so `hide_label` + `field=` composes.

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
which one it's paired with. One easy-to-miss HEEx gotcha here, same class of
bug as `Box`'s `tag="pre"`: the textarea's value must be written as
`<textarea ...>{@value}</textarea>` with **zero whitespace** between the
opening tag's `>` and `{@value}` — a newline there gets preserved as a
leading blank line in every browser's rendering of `<textarea>` content.

`color`'s effect is invisible in a plain (unfocused) screenshot since it's
entirely a `:focus-within` style — this was verified by simulating a real
DOM focus via Chrome DevTools Protocol (`element.focus()` + read
`getComputedStyle`) rather than trusting a static render, the same rigor
applied to any state that only exists on `:hover`/`:focus`/`:active`.

`variant="outlined"`'s border has a real notch cut into it around the
floated label (MUI's "notched outline") via an actual `<fieldset>`/
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

## Data display: the Table family (`Table`, `TableContainer`, `TableHead`, `TableBody`, `TableRow`, `TableCell`, `TableFooter`)

Modeled on MUI's Table components — one small function component per table
part, composed by the caller (see `PhoenixPaper.Table`'s moduledoc for the
full composition example). No `TableSortLabel` — `TableCell`'s
`sortable`/`sort_direction` attrs give the sort-header *look* (a clickable
header with a direction arrow), but wiring an actual sort click to actual
reordered data is the caller's LiveView, same as it would be for a
hand-rolled `<th>`. `TablePagination` arrived in 0.3.0, see "Navigation:
`Pagination` and `TablePagination`" below.

`dense` (`Table`) and `sticky_header` (`Table`), and `striped` (`TableBody`)
cascade to every descendant cell via plain CSS descendant selectors
(`[&_td]:py-1.5`, `[&>tr:nth-child(even)]:bg-...`) rather than an attr
threaded through every `TableCell` a caller writes — unlike MUI's React
context, HEEx has no mechanism for a parent to reach into a child
component's own assigns (the same limitation `ButtonGroup`'s moduledoc
documents for `color`/`variant`), but a *padding/background* cascade needing
only one class expressible as a selector works here specifically because CSS
descendant selectors match on real DOM nesting, not component boundaries —
`<table>` → `<td>` is real DOM regardless of which function rendered each.
This trick doesn't generalize to arbitrary-prop cascading like MUI's
`size`/`color`, only to needs a single compound selector can express.

That same trick is also *why* `TableRow`'s `selected` needs
`!bg-pp-primary/10` (Tailwind's important modifier) instead of a plain
`bg-pp-primary/10`: `TableBody`'s `striped` sets its background via
`[&>tr:nth-child(even)]:bg-...`, a compound selector with higher CSS
specificity than a bare class on the row itself, so without `!important` a
selected-and-striped row would silently show the stripe, not the selection
— found by actually screenshotting a selected+striped row, not by reasoning
about specificity in the abstract (see "Tailwind class safety" above for
why every one of these class strings has to be written out literally rather
than interpolated, same rule as everywhere else).

## Data display: `Avatar`, `Badge`, `Chip`, and `Tooltip`

Four MUI-parity components added together.

- **`Avatar`** layers an `<img>` (when `src` is given) over an always-
  rendered fallback (the `:inner_block` slot — initials or an icon — or,
  failing that, a generic person icon), rather than switching between them
  server-side. A vanilla `onerror="this.style.display='none';"` on the
  `<img>` (same "small snippet, no hook" precedent as `Ripple`) is what
  reveals the fallback on a broken image, matching MUI's own children-on-
  error behavior without a LiveView round-trip or an `onError` callback to
  wire up. `size` (`small`/`medium`/`large`) is a convenience this library
  adds — MUI's own `Avatar` has no size prop, expecting `sx`/`className`
  instead. No `AvatarGroup`: the overlapping-stack look is a plain flex
  container with `-space-x-*` and a `ring-2 ring-pp-surface` per avatar,
  already reachable with Tailwind alone — not a real gap the way
  `Snackbar`'s missing queueing is, so no dedicated component for it.

- **`Badge`** overlaps a small count/status indicator on its child's
  corner. Hiding logic matches MUI's `Badge` exactly, including a
  perhaps-surprising edge case: `invisible or (content == 0 and not
  show_zero) or (is_nil(content) and variant == "standard")` — a
  `variant="dot"` badge with `content={0}` is hidden by default same as
  `standard`, only a `nil` content is the one case `dot` treats specially
  (stays visible, e.g. a blank "online" indicator). `color` defaults to
  `"error"`, not a `"default"` gray like MUI — this library's `color` scale
  is `primary`/`secondary`/`tertiary`/`error` plus `success`/`warning`/
  `info` (see `Alert`), no eighth neutral token exists purely for `Badge`,
  and an unread-count badge reading as attention-red is the far more common
  real case anyway. The wrapping `<span>`'s `relative inline-flex shrink-0`
  is a hardcoded literal, not gated by `paperize` — same reasoning as
  `Autocomplete`'s anchor `<div class="relative">` (see "The `paperize`
  contract" above): it's positioning plumbing the badge can't work without,
  not part of the visual skin.

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

- **`Tooltip`** is pure CSS: a named `group/tooltip` wrapper with
  `group-hover/tooltip:`/`group-focus-within/tooltip:` (named so an outer
  `group` can't trigger it). MD3's `plain` (`inverse-surface`) and `rich`
  (`surface-container` with subhead and actions, kept open while hovered
  because the gap to the trigger is padding, not margin) variants. Showing
  waits `delay-300`, hiding is immediate. No arrow (MD3 has none).
  Viewport flipping is the optional hook's (tooltips need an `id` for it).

  **A verification dead-end worth knowing about, so it isn't re-walked**:
  an early headless-Chromium check of the hover reveal seemed to show
  `group-focus-within:opacity-100` losing to the base `opacity-0` utility
  once compiled alongside this library's full real stylesheet (thousands
  of other classes) — but disappeared as soon as `transition-opacity`
  duration was removed from the test. Root cause, confirmed via
  `element.getAnimations()`: the element's opacity transition's
  `playState` stayed `"running"` forever and never advanced, even past its
  150ms duration — headless Chromium's `--virtual-time-budget` fast-forwards
  timers but doesn't reliably drive the compositor frames a CSS
  *transition* (as opposed to an instant style change) needs to progress.
  Every other component's tests in this library check instant class/attr
  presence, never an animated property's settled value, which is why this
  never came up before. The CSS itself was correct the whole time — nothing
  in `Tooltip`, `Badge`, or `Chip` needed changing. If a future headless
  check of any *transitioning* property comes back "stuck," suspect the
  test methodology before the component.

## Feedback (`Alert`, `Backdrop`, `Dialog`, `Progress`, `Skeleton`, `Snackbar`)

Modeled on MUI's Feedback category, restyled to MD3 in 0.4.0:

- `Snackbar` is always `inverse-surface`; MD3 has no colored snackbars,
  so 0.3's `color` attr is gone.
- `Dialog` is MD3's basic dialog (28dp, `surface-container-high`, hero
  `icon`) plus `fullscreen`/`responsive` variants.
- `Progress` follows the 2024 MD3 spec: indicator/track gap, stop dot, and
  Expressive `wavy` (a box masked by a repeating SVG wave tile whose
  `mask-position` slides) and `thickness`.
- `LoadingIndicator` morphs a 72-point polygon through seven MD3 shapes
  with CSS `d: path()` keyframes, generated offline from polar functions.
  The hook carries the same functions for Safari.
- `BottomSheet`/`SideSheet` reuse `Dialog`'s exact mechanism.

Two older things are still worth knowing before touching any of these:

**`Alert`/`Snackbar` needed a new, separate color axis.** Every other
component's `color` attr picks from `primary`/`secondary`/`tertiary`/`error`
— brand/action colors. `Alert`'s `severity` picks from
`success`/`info`/`warning`/`error` — status colors, a different concept that
happens to share the name `error` (and does mean the same red) but has no
brand equivalent for "success" or "info" or "warning". Rather than force
`Alert` onto the existing 4-color scale (which has no green or amber), added
`--color-pp-success`/`-warning`/`-info` (+ `-on-*` pairs) to
`priv/static/phoenix_paper.css`, in both the light (`@theme`) and
`[data-theme="dark"]` blocks. (A bundled alternate brand palette, removed
in 0.3.0, deliberately left them out: status colors aren't part of a brand
identity swap, so an app's own palette override should usually leave them
alone too.)
(Older versions of this library also required registering any new `pp-*`
token in `mix.exs`'s `color_classes` list, for a class-merge dependency
that's since been dropped — see "Overriding built-in classes via `class`"
above. A new color token today needs nothing beyond the CSS file itself.)

**`Dialog` was the first component that isn't stateless-and-simple**
(`Menu` is the second — see "Navigation: `Menu`" above). Every other
component in this library either needs no interactivity (most of them), a
tiny bit of pure-CSS trickery (`NavigationRail`, `Rating`, checkbox/switch tricks),
or genuine server-tracked state as a `Phoenix.LiveComponent`
(`Autocomplete`, `TransferList`). `Dialog` needs client-side show/hide with
transitions, backdrop click-to-close, Escape-to-close, and focus trapping —
none of which need a LiveComponent's server round-trip, so it uses the exact
mechanism `mix phx.new`'s own generated `core_components.ex` modal already
uses: always rendered (hidden via CSS), `Phoenix.LiveView.JS` commands
(`JS.show`/`JS.hide`/`JS.exec`/`JS.focus_first`/`JS.pop_focus`) for the
transitions, and `Phoenix.Component.focus_wrap/1` (a *built-in* Phoenix
component backed by the `Phoenix.FocusWrap` hook that ships with
`phoenix_live_view.js`) for tab-focus trapping — not a hook this library
wrote. If you've used the generated modal before, `PhoenixPaper.Dialog` is
that same shape with Material chrome. `max_width` (since 0.2.6, default
`md` = the old fixed `max-w-md`) is a literal `max_width_class/1` clause
per value, and it goes on the **focus-wrap container**, not the `Paper`
panel (fixed in 0.2.7): the `flex items-center justify-center` row sizes
its direct child, the container, which has no width of its own. With
`w-full max-w-*` on the panel, `w-full` resolved against a shrink-to-fit
container, so a canvas or other no-natural-width child collapsed the
dialog, and long text widened the container past the panel and pushed it
off-centre. Now the container is `w-full max-w-*` (paperize-gated) and
the panel is plain `w-full`. Verified by measuring the panel in Chromium
for canvas, short and long content at 1280px and 500px viewports. The one non-obvious wiring detail:
`data-cancel` has to live on the *outermost* element (the one
`JS.exec("data-cancel", to: "##{id}")` actually targets by CSS selector),
not on the inner `Paper` content — putting it on the wrong element means
`JS.exec` finds nothing and Escape/backdrop-click silently do nothing.

`Progress`'s circular variant is real SVG (`stroke-dasharray`/
`stroke-dashoffset` computed from `value`, with MD3's gap between
indicator and track worked out in Elixir); the indeterminate ring is the
same SVG circle with a rotating, growing/shrinking dash
(`pp-circular-rotate`/`pp-circular-dash`), and the wavy ring is a path
precomputed at compile time. `Skeleton`'s `animation="pulse"` is Tailwind's own built-in
`animate-pulse` (nothing to add); `"wave"` needed a real `@keyframes` block
in `priv/static/phoenix_paper.css`, the same as `Progress`'s indeterminate
linear bar — animate-spin/animate-pulse cover the other two, but there's no
built-in Tailwind animation for a sweeping shimmer or a sliding bar.

`Snackbar`'s `anchor_origin` (6 corner/edge positions) and `transition`
(`grow`/`fade`/`slide`/`none`, another set of one-shot `@keyframes`
utilities same as `Skeleton`'s `wave`) came later, matching MUI's own
`Snackbar` page — `transition` only animates the *entrance*; see
`PhoenixPaper.Snackbar`'s moduledoc for why an exit transition and
consecutive-snackbar queueing still aren't built in (each needs either the
`Dialog`-style always-rendered-plus-`JS` machinery, or actual state a
stateless function component has nowhere to hold).

`autoHideDuration` *did* land, as opt-in `auto_hide_duration` (ms) paired
with `on_close` (a `JS` — MUI's close-IconButton pattern, rendered as a
trailing ✕). No JS hook: a standalone zero-footprint `<span
class="pp-snackbar-timeout">` inside the chip runs a no-op `opacity: 1 → 1`
CSS animation of `var(--pp-snackbar-timeout)` duration, and its
`onanimationend` (a raw inline handler — legal because the `<span>` isn't
a function component, same latitude `ThemeToggle`'s `onclick` uses) clicks
the ✕. It's a *child* span, never the root, so its `animation` shorthand
can't clash with the root's own entrance `transition` animation. Still
off by default — the server usually owns "is this message live"
(`Process.send_after/3` clearing the `open` assign); the client timer is
for the no-round-trip case, i.e. `pp_flash_group`.

`positioned` (default `true`) was split out of the all-or-nothing
`paperize` gate: `positioned={false}` drops only the `fixed inset-x-4 …`
anchor classes, keeping the inverted chip/elevation/transition. That's
what lets `PhoenixPaper.Flash` stack several chips inside its own `fixed`
corner container instead of each one anchoring itself to the same spot.

## Feedback: `PhoenixPaper.Flash` (Phoenix flash → snackbars)

`pp_flash_group/1` is the Material counterpart of a generated
`core_components.ex`'s `flash_group/1` — drop it once in the root layout.
It reads `:info`/`:error` (or whatever `kinds` lists) from `@flash` via
`Phoenix.Flash.get/2` and renders one `pp_snackbar positioned={false}` per
present message inside a `fixed` corner stack (`flex flex-col gap-2`).

- **Dismiss needs no LiveView handler.** The ✕ is
  `JS.push("lv:clear-flash", value: %{key: kind})` — `lv:clear-flash` is
  handled by the LiveView JS client itself: it clears that flash key and
  the server re-renders without it, so the `:if={@message}` on the chip
  goes false and it's gone. `auto_hide_duration` threads straight through
  to each chip and fires the *same* push on the timer.
- **Monochrome by kind, on purpose.** Material snackbars are a single
  inverted surface regardless of severity (the `Snackbar` moduledoc's
  own note) — so the kind only picks a leading heroicon
  (`icon_name/1`: info/success/warning/error recognised, anything else no
  icon), never a background color. Colored severity surfaces = an
  `Alert` inside a bare `pp_snackbar`.
- **`role`** is `alert` for `:error`, `status` otherwise.
- **`connection_notices`** (opt-in, since 0.2.4) renders the
  `:client-error`/`:server-error` "connection lost" chips a generated
  `core_components` shows. They're a *different* mechanism from flash (no
  server flash entry — the server is what's unreachable): two
  `pp_snackbar`s rendered `hidden`, with `phx-disconnected` running
  `JS.remove_attribute("hidden", to: ".phx-client-error #pp-flash-client-error")`
  (resp. `phx-server-error`) and `phx-connected` putting `hidden` back.
  Plain attribute toggling, not `JS.show`/`JS.hide`: `JS.show` sets an
  inline `display: block`, which would override the chip's own `flex`.
  Tailwind's preflight makes `[hidden]` `display: none !important`, so
  `hidden` wins over the chip's `flex` class while it's set.

The `stack_classes/1` container is `pointer-events-none` with
`[&_[data-pp-component=snackbar]]:pointer-events-auto` so the transparent
gaps between/around chips don't eat clicks on the page beneath — the same
`data-pp-component` compound-selector reach used elsewhere.

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

## `PhoenixPaper.ThemeToggle`, and a class-merging gap it exposed early

**Since 0.2.4 the default is `variant="segmented"`**: System / Light /
Dark icon buttons, System selected by default (it *removes* `data-theme`).
Everything below about the sun/moon switch now describes
`variant="switch"`, kept for callers who want the two-state look. The
segmented control deliberately avoids the switch's problems rather than
working around them:

- **Its selected state is CSS keyed off the ancestor's `data-theme`**
  (`[[data-theme=dark]_&]:translate-x-16` on the indicator and the
  matching button colors), never state stored on the component. So there's
  no checkbox property for a LiveView patch to reset (the hydration bug
  below can't happen), no cross-instance sync script, and System is simply
  "neither light nor dark matched". The trade-off: it reads the *nearest*
  `data-theme` ancestor, so a scoped `target` only shows correctly when the
  toggle sits inside that target; documented, not worked around.
- **No `aria-pressed`**, for the same reason: it would have to be set by
  JS on click and a patch can undo it. Each button has `aria-label`/`title`
  instead.
- **Persistence** writes `localStorage["phx:theme"]` (removed for System)
  only when `target="html"` — the exact key and semantics of Phoenix 1.8's
  generated root layout script, so a 1.8 app restores it on reload with no
  setup; the moduledoc has a four-line `<head>` snippet for other apps.
  The switch variant writes the same key.
- **The switch now follows the same rule.** It used to take its look from
  its checkbox whenever `data-theme` was set, assuming a click had set
  both together. Wrong after a reload with a saved `"dark"` (the server
  renders the checkbox at `default_checked`, so: dark page, "off / sun"
  switch) and after any theme change made elsewhere (the segmented
  control, Phoenix 1.8's picker). Its track/thumb/icons now carry
  `[[data-theme=dark]_&]:!...`/`[[data-theme=light]_&]:!...` classes;
  the `!` is needed because `has-[:checked]:` ties them on specificity.
  The checkbox only matters with no `data-theme` (System, OS light); the
  CSS-file rule still covers System + OS dark. Verified in Chromium for
  all six combinations of theme (none/dark/light) and OS preference, with
  the checkbox both checked and unchecked.
- Verified in headless Chromium by clicking each button: `data-theme`
  removed/`light`/`dark`, `localStorage` matching, and two toggles on the
  page (one inside a `TopAppBar`) moving their indicators together
  (`translate` 0 / 32px / 64px — note Tailwind v4's `translate-x-*` sets
  the standalone `translate` property, so `getComputedStyle(...).transform`
  reads `none`; read `.translate`).

Rewritten from a thin `PhoenixPaper.Switch` wrapper to its own markup so a
sun/moon icon could live *inside* the sliding thumb (swapped via a
`peer-checked:` compound selector reaching into the thumb's own children —
`Switch` itself has no attr for that). Two things worth knowing:

- **Deliberately no `pp-*` brand color anywhere in it** (thumb fixed
  white, track a neutral translucent gray) even though `Switch`'s own
  thumb/track go `pp-primary` when checked. In 0.3 a theme toggle usually
  sat in a `pp-primary` app bar, where a `bg-pp-primary` thumb would have
  vanished; MD3 top app bars are surface-colored, but the switch keeps the
  neutral look so it still reads on a vibrant `Toolbar`. (The segmented
  variant does use MD3 roles: a `secondary-container` indicator.)
- **Found a real gap in the `tails` hex package this library used to
  depend on, before class-merging was dropped entirely** (see "Overriding
  built-in classes via `class`" above): passing `class="size-3"` to
  override `PhoenixPaper.Icon`'s default `size-5` left **both** classes in
  the merged output (verified directly: `Tails.classes("size-5 size-3")`
  returned `"size-3 size-5"`, not just `"size-3"`) — that version of
  `tails`'s conflict-resolution ruleset didn't know about Tailwind's
  `size-*` shorthand (a newer utility; the ruleset predated it), so it
  didn't treat two `size-*` classes as conflicting the way it did e.g. two
  `text-*` or `bg-*` classes. With both classes present, which one
  actually won was down to Tailwind's own internal utility ordering in the
  generated stylesheet — not something to rely on. Fixed the same way
  `TableRow`'s `selected` state already does for its own specificity
  fight: `class="!size-3"` (Tailwind's `!important` prefix), which wins
  regardless of generation order. This was the first sign that a "merge"
  dependency only ever helps for the cases it happens to know about and
  silently does nothing for the rest without any error or warning — the
  same `!` pattern this one gap needed is now how every override works,
  everywhere in this library, since there's no merge step left at all.
  (Since 0.3.0 `Icon` has a `size` attr, so the toggle uses `size="xs"`
  instead; `size="none"` is the escape hatch for a size outside its
  presets.)
- **First version's `<script>`-based system-preference sync looked right
  and wasn't** — worth knowing in detail since it's the kind of bug that
  only shows up on a real dark-OS machine, never in a static render or a
  test. It set the checkbox's `checked` *property* to match
  `matchMedia('(prefers-color-scheme: dark)')` on mount (the same "small
  vanilla snippet, no hook" precedent `Ripple`/`NumberField` use). That
  script itself ran fine — but Phoenix LiveView's connected-mount
  hydration re-renders and morphdom-patches the page shortly after the
  dead-rendered first paint, and that patch can replace the checkbox
  element with a fresh one built from the *server's* render (which has no
  way to know the client's OS preference and always has
  `default_checked`), silently discarding the script's mutation. Visible
  symptom on an actual dark-OS machine: the page renders correctly dark
  (the CSS fallback is unaffected by any of this), but the toggle *looks*
  set to light — and because the original click handler read the
  (silently-reset) `checked` property to decide `"dark"` vs `"light"`, the
  first click just reasserted "dark" (a no-op the user couldn't see,
  since the page was already dark via the system fallback), so it took
  *two* clicks to actually reach light.

  Fixed at both ends, neither depending on the other:
  1. The click handler now **computes the effective theme itself** —
     `data-theme` if set, else `matchMedia` — and flips to the opposite,
     rather than ever trusting the checkbox's own `checked` property. This
     alone fixes the double-click bug regardless of whether anything
     synced the checkbox's visual state correctly.
  2. The toggle's *first-paint appearance* now syncs via a `@media
     (prefers-color-scheme: dark)` block in `priv/static/phoenix_paper.css`
     that fakes the "checked" look (track color, thumb position, icon
     swap) directly in CSS, scoped to `html:not([data-theme])` — CSS has
     no hydration race to lose, so this can't be silently undone the way
     the script's property mutation could. It's purely cosmetic (the
     underlying checkbox is never actually "checked" until a real click
     happens), which is fine because (1) no longer depends on it being
     accurate.

  One HEEx fact learned along the way, now moot but worth remembering for
  next time: `~H` does **not** parse `{...}` interpolation inside a
  `<script>` tag's body at all — it's treated as raw text, same as a
  browser's own HTML parser treats `<script>`/`<style>` content. A
  `{some_function()}` call inside `<script>...</script>` compiled with an
  "unused function" warning, meaning it was silently never invoked — the
  script body has to be written as literal text directly in the template.
- **Multiple instances now stay in sync, scoped by `target`**: a page with
  more than one `pp_theme_toggle` (e.g. one in a `TopAppBar`, another in a
  settings panel) used to leave the other one visually stale after a
  click, since each toggle's `onclick` only ever touched its own checkbox.
  Fixed by giving the outer `<label>` a `data-pp-target={@target}`
  attribute and having the click handler, right after computing `next`,
  run `document.querySelectorAll('[data-pp-component="theme-toggle"]
  [data-pp-target="..."] input[type=checkbox]')` and set every match's
  `checked` property (the clicked checkbox matches its own query too, so
  there's no separate `cb.checked = ...` line anymore — one code path
  covers both "self" and "siblings"). Scoped to matching `target`, not
  every toggle on the page unconditionally: a toggle bound to
  `target="#preview"` and one bound to the default `target="html"`
  represent two independently-meaningful pieces of state, so syncing them
  together would be wrong even though both are `pp_theme_toggle`s. Pure
  `querySelectorAll` at click time — no hooks, no PubSub, works across
  LiveViews on the same page just as well as within one.

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
the token directly. Expressive buttons don't use `Shape`: their shape is
`round`/`square`, with explicit pixel radii so the morph can animate.

## Spacing

`PhoenixPaper.Spacing` maps named tokens (`:xs`, `:sm`, `:md`, `:lg`, `:xl`,
`:"2xl"`) to literal Tailwind spacing classes (`padding/1`, `gap/1`).
Tailwind's default scale is already a 4px grid, compatible with Material's
8dp baseline grid, so this is a naming layer for consistency (a
project-wide density change becomes a one-file edit), not a new scale.

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

1. Add `{:phoenix_paper, "~> 0.4"}` to `mix.exs` (it needs
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
5. Optional: register the hook (`import PhoenixPaperHooks from
   "phoenix_paper"`, spread into the LiveSocket's `hooks`) and set
   `config :phoenix_paper, hook: true`.

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
in every other form component's `field=` clause (`Input`, `Checkbox`,
`Switch`, `RadioGroup`, `Rating`, `NumberField`, `Select`): `field=` never
actually populated `name`/`id`/`value`/`checked` from the
`Phoenix.HTML.FormField`. Confirmed by rendering `<.pp_input field={@form[:email]} />`
directly and finding the output `<input>` had no `id`, `name`, or `value`
attribute at all — not a hypothetical, an actual broken render. Zero
existing tests caught it because not one of those seven components' test
files exercised the `field=` code path at all (all now do, and all now
pass — see below).

**The mechanism**: every affected attr (`value`, `name`, `id`, `checked`)
is declared with `attr(..., default: nil)` (or `default: false`,
`default: 0` for `Rating`). Phoenix's `attr` macro fills in that default
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
`checked || fallback` would wrongly discard. For `Rating`'s `value`
(declared `default: 0`, not `nil`, since a star rating's natural "unset"
is zero stars) the check is `assigns.value == 0` instead of `is_nil/1`.

None of these fixes can perfectly distinguish "caller explicitly passed
this exact value" from "caller didn't pass it, so the declared default
applied" — that information is genuinely gone by the time the function
body runs, a real limitation of `Phoenix.Component`'s attr system, not
something specific to this library. Treating "value equals the attr's own
declared default" as "not explicitly set" is the best available
approximation, and matches the intent every one of these callers actually
had.

**Test-coverage lesson**: every one of `Input`/`Checkbox`/`Switch`/
`RadioGroup`/`Rating`/`NumberField`/`Select`/`Slider`'s test files now has
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
