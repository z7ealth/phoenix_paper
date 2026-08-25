# AGENTS.md — PhoenixPaper base rules

PhoenixPaper is a Material Design component library for **Phoenix**, in the
spirit of [ember-paper](https://github.com/miguelcobain/ember-paper) (the
Ember.js Material Design addon), styled with **Tailwind CSS**. It ships as a
hex package (a component library, not a Phoenix app) that a Phoenix project
adds as a dependency.

This file is the ground truth for how the library is built. Read it before
adding or changing a component.

## Project shape

- `lib/phoenix_paper/*.ex` — one module per component (`Button`, `Card`,
  `Icon`, `Checkbox`, `Input`, `Switch`, `RadioGroup`, `Select`,
  `ButtonGroup`, `ToggleButton`, `Fab`, `Rating`, `Slider`, `NumberField`,
  `Autocomplete`, `TransferList`, `AppBar`, `Drawer`, `Breadcrumbs`, `List`, `ListItem`,
  `ListSubheader`, `Divider`, `Box`, `Container`, `Stack`, `Grid`,
  `GridItem`, `ImageList`, `ImageListItem`, `Paper`, `Typography`, `Table`,
  `TableContainer`, `TableHead`, `TableBody`, `TableRow`, `TableCell`,
  `TableFooter`, `Alert`, `Backdrop`, `Dialog`, `Progress`, `Skeleton`,
  `Snackbar`, `Accordion`, `AccordionSummary`, `AccordionDetails`,
  `AccordionActions`, ...), plus `Helpers`, `Elevation`, `Spacing`, `Shape`,
  `Ripple`.
- `lib/phoenix_paper/components.ex` — `use PhoenixPaper.Components` imports
  every component's render function at once.
- `priv/static/phoenix_paper.css` — the Tailwind v4 theme (color tokens,
  elevation utilities). Consumers `@import` it.
- `test/phoenix_paper/*_test.exs` — one test file per component.

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
  - `class` (`:any`, default `nil`) — merged with `Tails`.
  - `rest` (`:global`) — for `phx-*` bindings, `id`, `data-*`, etc.
- Register new components in `PhoenixPaper.Components.__using__/1` in the
  same change.
- The one-module-per-component rule bends for a small control that's
  meaningless without its parent component — `PhoenixPaper.Drawer` exports
  both `pp_drawer/1` and its `pp_drawer_toggle/1` hamburger button from
  the same module. It doesn't bend for anything independently reusable:
  `PhoenixPaper.ListItem` is its own module (and works standalone, e.g.
  inside a `Card`) rather than living inside `PhoenixPaper.List`, because a
  styled list item is useful on its own. When in doubt, split it out.

## Conditional root tag: link vs. static element

HEEx can't parameterize a tag name (`<{@tag}>` isn't valid), so a component
that should render as `<a>` when it's a link and a plain `<div>`/`<span>`
otherwise (`ListItem`) needs two `:if`/`:if={!...}` branches in the same
template, each rendering its own root element. Factor the shared inner
markup into a private function component (e.g. `ListItem`'s `item_content/1`)
called from both branches instead of duplicating it — passing the same
`assigns` map through works fine since it's still just a Phoenix.Component
function receiving assigns, not a macro needing anything special.

`Typography` hits the same wall with more branches (`variant="h1"` needs
`<h1>`, `variant="body1"` needs `<p>`, `variant="code"` needs `<code>`, ...)
— it's just one `:if` per distinct *tag* (grouping variants that share a
tag into one `:if={@variant in [...]}`), not per variant, and the inner
content (`render_slot(@inner_block)`) is a single line repeated across
branches rather than factored out, since factoring it here would cost more
than it saves. Unlike MUI's `Typography`, there's no `component` prop to
pick the tag independently of `variant` — one attr driving both keeps this
to 8 branches instead of the cross product of every variant with every
possible tag.

## The ripple effect

`PhoenixPaper.Ripple` implements the Material ripple (a circle expanding
from the click point, then fading) as a small vanilla inline `onclick`
snippet — no JS hook, no bundler, same philosophy as `NumberField`'s
steppers. Every genuinely click-driven component (`Button`, `Fab`,
`ToggleButton`, a linked `ListItem`) exposes a `ripple` boolean attr,
**default `true`**, wired identically:

```elixir
class={Helpers.classes(@paperize, [..., Ripple.container_classes(@ripple)], @class)}
onclick={Ripple.on_click(@ripple)}
```

Two things worth knowing before touching this:

- **It has to be `onclick`, not `onpointerdown`/`onmousedown`.** Phoenix's
  HEEx compiler statically validates `on*` attributes against a fixed
  allowlist for function components (see
  `Phoenix.Component.Declarative`'s `@globals`) — that list has `onclick`
  and the `onmouse*` family, but no `onpointer*` events at all. This only
  bites when the attribute has to pass through a function component like
  `Phoenix.Component.link/1` (which `ListItem` renders through when it's a
  link) — a raw HTML tag like `<button>` isn't attr-validated at all, so
  `onpointerdown` would have compiled fine on `Button`/`Fab`/`ToggleButton`
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
(`Button`, `Fab`, `ToggleButton`, `NumberField`'s steppers, `Autocomplete`'s
option button, `TransferList`'s move buttons) before being caught and
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
  typography. A caller-supplied `class` is still merged on top via
  `PhoenixPaper.Tails` (last conflicting utility wins), so small tweaks
  don't require dropping into `paperize={false}`.
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
`ripple` (`Button`, `Fab`, `ToggleButton`, `ListItem`) fires via an
`onclick` attribute, not a class, so `Helpers.classes/3` dropping
`paper_classes(...)` under `paperize={false}` doesn't touch it — the
ripple would still fire with nothing to size/clip it. Every ripple-capable
component computes an effective `ripple and paperize` value and uses
*that* everywhere `ripple` would otherwise appear (see
`PhoenixPaper.Ripple`'s moduledoc). Keep that pattern for any new
component that adds `ripple`.

## `PhoenixPaper.Tails`, not plain `Tails` — and updating it when adding a color token

`Helpers.classes/3` merges through `PhoenixPaper.Tails`, a `Tails.Custom`
instance, **never** the plain `Tails` module directly. This isn't
stylistic: plain `Tails` only recognizes Tailwind's own built-in palette
names when deciding whether two classes conflict. It has no idea `pp-*` is
a color family, so when a class sharing a prefix with a `pp-*` color shows
up in the same merge — a font-size utility and `text-pp-*` both start
`text-`; a border/outline *width* utility and `border-pp-*`/`outline-pp-*`
both start `border-`/`outline-`) — it can't tell they're different CSS
properties, lumps them into one "conflicting" group, and silently keeps
only the last one. This was a real, already-shipping bug: `focus-visible:
outline-2` was being dropped by every component using the standard focus
ring pattern (`outline-2` + `outline-pp-primary` together), quietly
shrinking every focus ring in the library to the browser default width.
`PhoenixPaper.Tails` is `Tails.Custom` told about `pp-*` via `color_classes`
specifically to fix this class of bug for good — see its moduledoc.

That configuration lives entirely in `mix.exs`, split across **two
mechanisms that are both required together** — this took two failed
attempts (verified against a real external app depending on this package
via `path:`, not just this package's own `mix test`, since that's what
actually exposed each gap) to land correctly:

- A plain `Application.put_env(:phoenix_paper, PhoenixPaper.Tails,
  color_classes: [...])` at the top of `mix.exs`, so the value is visible
  when `PhoenixPaper.Tails` itself compiles (`Application.compile_env/2`
  reads whatever's in the application environment *at that moment* — a
  `config/config.exs` file can't help here at all, since **Mix ignores
  `config/config.exs` from dependencies** entirely; `mix.exs` works because
  Mix always evaluates a dependency's `mix.exs` first, before any of its
  `lib/*.ex`, to learn how to build it).
- The *same* value again, in `application/0`'s `env:` key. This one's
  needed because `Application.compile_env/2` doesn't just read a value —
  it also makes Mix validate that value against whatever `:phoenix_paper`
  is loaded with when the OTP application actually **starts** (e.g. when
  `PhoenixPlayground.start/1` boots the full app tree in `dev.exs`).
  Application loading resets the app's environment from its compiled
  `.app` resource file, discarding the ad-hoc `put_env` from step one —
  `env:` is what bakes a value directly into that resource, so it's there
  when loading happens. Without it, `mix compile`/`mix test` pass (they
  never start the OTP application) but booting a real LiveView server
  crashes with a `Mix.Error` about mismatched compile-time/runtime values.

Using only one of the two isn't enough — the `mix.exs` module comment
where both live spells out exactly which failure mode each one alone
leaves open, if you're ever tempted to simplify it back down to one.

**If you ever add a new `pp-*` token** (a new palette color in
`priv/static/phoenix_paper.css`, say), add its name to the shared
`color_classes` list in `mix.exs` too — otherwise it inherits this exact
bug the moment it's combined with a same-prefixed non-color utility.

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
  value. `PhoenixPaper.Button.elevation_classes/2` shows the split: the
  common case (`nil` = default elevation) is one literal string with the
  hover variant baked in; an explicit override falls back to a plain,
  un-animated `Elevation.class/1` call.

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
entirely (`Drawer`'s mobile panel, opened by a hamburger button that lives
inside `AppBar`, nowhere near the drawer): a plain `<label for={checkbox_id}>`
checks a checkbox regardless of where the label sits in the document — label
targeting is id-based, not sibling-based. Only the elements that need to
*react* to the checkbox (the drawer panel, its backdrop) have to be its
actual siblings for `peer-checked:` to reach them; the button that flips it
doesn't.

## Stateless function components vs. `Phoenix.LiveComponent`

Every component is a stateless `Phoenix.Component` function (`pp_*/1`) by
default — that's the whole point of the `pp_` import convention. Reach for a
`Phoenix.LiveComponent` only when a component needs interactive state a
single render pass can't express from its attrs alone (`Autocomplete`'s open
dropdown + filtered list, `TransferList`'s left/right item split). Those two
are the only such components on purpose: they aren't imported by
`PhoenixPaper.Components` (there's no function to import — they're used
directly as `<.live_component module={PhoenixPaper.Autocomplete} ...} />`),
they only work inside a LiveView (not a plain dead/controller-rendered
page), and that limitation should be called out in their moduledoc. Default
to a stateless function component; justify a `LiveComponent` explicitly.

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

There is no shipped `CodeSnippet` component — `dev.exs`'s catalog is the
only place PhoenixPaper renders source code, and it does that with
highlight.js (a real, established syntax highlighter) rather than a
hand-rolled component; see "Dev / live preview" below.

## Surfaces: `Accordion`, `AccordionSummary`, `AccordionDetails`, `AccordionActions`

Modeled on MUI's `Accordion` — pure CSS, no JS/LiveView, the same hidden-
checkbox-plus-`peer-checked:` trick as `Drawer`/`Rating`. `pp_accordion/1`
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

## Navigation: `AppBar` (renamed from `Navbar`)

Renamed to match MUI's own component name (`Navbar` was this library's own
earlier, non-MUI name for the same thing) — the rename touched every
reference across the repo: the module/file/test file, `components.ex`'s
import, `Drawer`'s moduledoc example (`AppBar` is the usual home for
`Drawer.pp_drawer_toggle/1`), `dev.exs` (including the live app bar at the
top of that catalog page itself, not just its own demo section), and
`README.md`. If you're hunting for old `Navbar`/`pp_navbar` references
after a `git blame` or an old branch, this is why they're gone.

Added full parity with MUI's `AppBar` props while renaming: `position` now
covers all five MUI values (`static`/`relative`/`sticky`/`fixed`/
`absolute`, not just the original three), `color` gained `"transparent"`
(no background/text-color classes, elevation ignored — MUI's `"inherit"`
was deliberately *not* added alongside it: in a plain-CSS-class component
there's no meaningful difference between "inherit color, keep default
background" and "no color classes at all", so one option covers both), and
a new `variant` attr (`"regular"`/`"dense"`) shrinks the toolbar row the
way MUI's `Toolbar variant="dense"` does. MUI's "prominent" app bar and the
notched bottom-app-bar-with-center-FAB pattern are deliberately not
built-in — neither is a single prop even in MUI itself (both are manual
layout/`sx` compositions in their own docs), so they're documented as
"compose it yourself" in `AppBar`'s moduledoc instead, the same treatment
`Table` gives `TablePagination`/`TableSortLabel`.

The inner toolbar `<div>` (the flex row arranging `:leading`/title/
`:actions`) keeps its layout classes **unconditional**, not gated behind
`paperize` like the outer `<header>`'s color/elevation/position classes
are — a deliberate exception to the "paperize={false} drops *all* built-in
classes" wording in the `paperize` contract above. There's no `class` attr
exposed on that inner div for a `paperize={false}` caller to rebuild the
three-region flex layout themselves, so dropping it would leave `:leading`/
title/`:actions` stacked with no arrangement at all and no way back — this
was a deliberate correction after an initial pass wired `Helpers.classes/3`
onto that div too, which would have made `paperize={false}` silently break
the component's basic layout instead of just its skin.

**Pitfall: a `Button`/`Fab`/etc. placed inside a colored `AppBar` needs an
explicit contrasting `class`, or its text is invisible.** `Button`'s
`variant="text"`/`"outlined"` color classes are always the *brand* color
(`text-pp-primary` for `color="primary"`, the default) — they don't know
or care what they're sitting on. Put one inside an `AppBar` with
`color="primary"` (also the default) with no override, and its text color
(`text-pp-primary`) exactly matches the app bar's own background
(`bg-pp-primary`) — not just low-contrast, *mathematically the same
color*, so the button is entirely invisible, not merely hard to read. This
bit `dev.exs`'s own theme-switcher buttons (`Indigo`/`Teal`/`Light`/`Dark`)
in the live top app bar — found from a user screenshot showing a blank
colored bar, not from any test (rendering the class list in isolation
looks completely fine; the bug only exists in the *combination* of two
components' independent, individually-correct defaults). Fixed by adding
`class="text-pp-on-primary hover:bg-pp-on-primary/10 focus-visible:outline-pp-on-primary"`
(or the `border-pp-on-primary`-inclusive variant for `variant="outlined"`)
to each affected button — plain `class` overrides via `Helpers.classes/3`'s
Tails merge, no component change needed, since `Button` has no way to know
its container's color and (like `ButtonGroup`/`Tabs`/`AppBar` itself)
isn't meant to. There's no general fix for this beyond "remember to
override text/border/outline color for brand-colored buttons placed on a
brand-colored surface" — the same caveat applies to any `Button` dropped
into a colored `Drawer` (see below) or `Card`.

## Navigation: `Drawer`'s `color` and reaching into nested `List`/`ListItem`

`Drawer` gained a `color` attr (`primary`/`secondary`/`tertiary`/`surface`,
default `surface` — unchanged prior behavior) so the whole panel can match
a colored `AppBar`. Unlike every other `color` attr in this library
(`Button`, `AppBar`, `Tab`, ...), which only ever touches the component's
*own* classes, `Drawer`'s colored variants also reach into
`List`/`ListItem`/`ListSubheader`/`Divider` — components that have no
`color` prop of their own and are normally styled for a neutral surface
background. This is a deliberate, narrow exception to "no cascading" (see
`ButtonGroup`'s moduledoc for the general rule): getting it wrong here
isn't a style mismatch, it's *actual invisibility* —
`ListItem`'s active-item highlight is `bg-pp-primary/10`, and layering
that over a `color="primary"` drawer's own `bg-pp-primary` background is
literally the same color blended with itself, which produces that exact
same color back with zero visible change, not just poor contrast. Found
by screenshotting a colored drawer with an active nav item, the same way
the `AppBar`-button pitfall above was found — a bug that only exists in
the combination of two independently-correct components, invisible from
reading either one's source in isolation.

The mechanism: `color_classes/1` for each brand color adds
`[&_[data-pp-component=list-item]]:text-pp-on-<color>`-style compound
selectors (plus matching ones for `list-subheader` text, `divider`
borders, hover, and the active-item highlight) — the exact same
`data-pp-component` compound-selector technique `Tabs`'s
`variant="full_width"` already uses to reach its child `Tab`s, just with
more targets. `ListItem`'s `active` attr now also sets
`aria-current="page"` (a real, independently-worthwhile accessibility
fix — it's the correct ARIA for "this is the current page in a nav list")
specifically so these selectors have a stable attribute to distinguish
the active item from the rest; without it there'd be no way to target
"the active one" from outside `ListItem` at all. The hover override is
scoped `:not([aria-current=page])` deliberately — omitting that guard
would make the active item's hover state and its always-on
`[aria-current=page]` background compete at *equal* CSS specificity
(one attribute selector each), which falls back to declaration order in
the generated stylesheet and would make the active item's highlight
opacity flicker unpredictably on hover depending on Tailwind's internal
class-authoring order, not anything under this codebase's control.

Because every override is written per-color as a fully literal string
(`color_classes("primary")`, `color_classes("secondary")`, ... — never
`"text-pp-on-#{color}"`), this follows the same "Tailwind class safety"
rule as everywhere else in the codebase, just with three more, longer
literal-string clauses than a typical `color_classes/1`.

## Navigation: `Tabs`, `Tab`, `TabPanel`

The first component family in this library where switching state is
*not* the checkbox/radio-plus-`peer-checked:`/`has-*` trick every other
interactive component (`Accordion`, `Drawer`, `Checkbox`, `Switch`,
`RadioGroup`, `Rating`) uses. `peer-*`/`has-*` can only express "is *some*
sibling checked" — they have no way to express "which *specific* one of N
siblings is checked," which is exactly what mapping a selected `Tab` to
its one matching `TabPanel` needs, especially since the panel usually
isn't even a DOM sibling of the tabs at all (MUI's own docs write
`TabPanel`s *after* the whole `Tabs` block, not interleaved with it, and
this library follows that). So `Tabs`/`Tab`/`TabPanel` switch state with
plain `Phoenix.LiveView.JS` commands (`add_class`/`remove_class`/
`set_attribute`/`show`/`hide`) fired from each `Tab`'s own `phx-click` —
same "no server round-trip, no assign to fight with on the next unrelated
re-render" approach `Dialog`/`Drawer` already use for boolean show/hide,
just extended to an *N*-way exclusive choice. `PhoenixPaper.Tabs.select/3`
is the one function building that whole op chain; it's `@doc false`-free
(intentionally public, like `Dialog.show/2`) so a trigger elsewhere on the
page could drive tab selection too.

Verifying this needed a different technique than every other
CSS-driven-toggle component this library has shipped: a static screenshot
only proves the *first-paint* markup/classes are right, it can't prove
the `phx-click` JS-command chain actually flips the right elements when
clicked, because that requires a real `phoenix_live_view.js` client
runtime to interpret. Fully bootstrapping that (a real `LiveSocket`, a
mounted view, a live route) would mean starting a real listening server —
out of bounds for how this repo is verified. Two lighter checks covered
the actual risk instead: (1) a unit test that calls `Tabs.select/3`
directly and pattern-matches the exact `%Phoenix.LiveView.JS{ops: [...]}`
list it returns, so a wrong selector/argument/op-order is caught as a
plain data-structure assertion with no browser involved at all; (2) a
headless-Chromium check that loads the real rendered HTML and manually
replays that *exact* op sequence via `element.classList`/`querySelectorAll`
(not the LiveView JS runtime, just plain DOM calls matching what it would
do), confirming the `data-pp-tabs-id="..."`/`data-pp-tab-panel-group="..."`
selectors actually resolve to the intended elements and only those — the
realistic failure mode here is a typo'd selector or an id built the wrong
way, not `Phoenix.LiveView.JS` itself misbehaving (that's already covered
by LiveView's own test suite).

There's no sliding indicator animation like MUI's — that needs measuring
a specific tab's pixel offset/width at runtime, a genuine client-side
layout query, and `Phoenix.LiveView.JS` only issues fixed DOM commands, no
custom computed logic, without a bespoke JS hook. The selected tab styles
*itself* instead (colored text + a persistent 2px border whose color
toggles), simpler visually but zero custom JS. There's also no roving
`tabindex` (MUI keeps only the selected tab in the normal Tab order) —
every tab stays normally focusable, a small deviation from strict ARIA
tablist authoring practice traded for not needing JS to manage focus too.

Like `ButtonGroup`, there's no group-level `color`/`orientation` that
cascades from `Tabs` down to every `Tab` — HEEx has no mechanism for a
parent component to reach into a child component's own assigns, so both
are set per-`Tab` and must be kept consistent with the parent `Tabs`
yourself.

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
`Drawer`, the checkbox's `id` is generated internally with
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
even under `paperize={false}`, the same deliberate exception `AppBar`'s
inner toolbar div makes and for the same reason: there's no `class` attr
exposed on an individual `<li>` for a `paperize={false}` caller to rebuild
that row layout themselves.

## Forms: `Slider` (MUI Slider parity)

Rewritten from `accent-color`-only styling to a fully custom
`::-webkit-slider-runnable-track`/`::-webkit-slider-thumb`/
`::-moz-range-track`/`::-moz-range-progress`/`::-moz-range-thumb` skin,
after a real screenshot showed the *unfilled* remainder of an
`accent-color`-only track rendering as a glaring near-white line on a dark
background — `accent-color` alone can color the thumb and the filled
segment, but leaves the unfilled remainder at the browser's own default
color with no way to control it. Verified empirically (not assumed) that
once you take over the track's own background via
`::-webkit-slider-runnable-track`, Chromium stops drawing `accent-color`'s
automatic fill for you at all, so the filled segment here is a manual
`linear-gradient` positioned by a `--pp-slider-percent` CSS custom
property — set inline by `PhoenixPaper.Slider` for the first paint, kept
in sync while dragging by the same "tiny vanilla inline script, no hook,
no bundler" approach `PhoenixPaper.Ripple`/`NumberField`'s steppers
already use. Firefox needs none of that: `::-moz-range-progress` is a
real pseudo-element Firefox sizes to the current value on its own.

All of this custom track/thumb CSS lives in `priv/static/phoenix_paper.css`
as hand-authored `@utility` blocks (matching `pp-elevation-N`/
`pp-skeleton-wave`'s existing pattern), not as Tailwind arbitrary-variant
classes on the component — the declarations needed (multi-stop gradients,
several pseudo-elements, custom properties) are too much for one-class-one-property
arbitrary variants to express cleanly. Four *complete*, mutually-exclusive
"shape" utilities (`pp-slider`/`pp-slider-small` × horizontal,
`pp-slider-vertical`/`pp-slider-vertical-small`) rather than a base
utility plus small per-axis/per-size overrides — two utilities both
setting the same pseudo-element's `background`/sizing from two classes on
one element is a same-specificity, source-order-dependent conflict (the
same class of risk `Drawer`'s colored variants' compound selectors
document above). Verified empirically via `getComputedStyle(...).getPropertyValue(...)`
in headless Chromium that combining a shape utility with a *color*
utility (`pp-slider-primary`, only ever setting `--pp-slider-color`) and a
*track-mode* utility (`pp-slider-track-none`/`-inverted`, only ever
setting `--pp-slider-fill-color`/`--pp-slider-fill-start`/`-end`) resolves
correctly regardless of which is textually later in the stylesheet — these
three categories never set the same custom property as each other, so
there's no analogous conflict between *them*.

Range sliders (`value={{low, high}}`) use the well-known "two overlapping
native range inputs" technique: each input's own track is made fully
transparent (`pp-slider-range-input`, reusing the exact same gradient
formula with both colors set to `transparent` rather than a separate
thumb-only utility), `pointer-events: none` on the input with
`[&::-webkit-slider-thumb]:pointer-events-auto`/
`[&::-moz-range-thumb]:pointer-events-auto` re-enabling it only on the
visible thumb, and a separate sibling `<div>` for the "between the two
thumbs" colored segment (something neither native input's own gradient
can express, since each only knows its *own* value/percent). A small
inline `oninput` script recomputes both thumbs' percentages and the
between-`<div>`'s `left`/`right` on every drag, and clamps a thumb that's
been dragged past the other one. This is a real, inherent limitation of
the technique (shared by every native-input-based range slider, not a
shortcut unique to this implementation) — documented as such in
`PhoenixPaper.Slider`'s own moduledoc rather than treated as a bug to
chase further.

`marks` renders through the native `<datalist>`/`list=` pairing —
real, declarative HTML tick marks (Chrome/Firefox both draw them and snap
the thumb near them), not a hand-rolled overlay. Labeled marks
additionally render a row of absolutely-positioned `<span>`s below the
track, positioned by the same percent math as the fill itself; this
positioning assumes `orientation="horizontal"` and isn't implemented for
vertical sliders.

`orientation="vertical"` uses `writing-mode: vertical-lr` (the current
standards-track way Chromium/WebKit make a range input vertical) plus the
older, still-supported non-standard `-moz-orient: vertical` for Firefox —
there is no vendor-neutral standard property for this yet, so both are
applied together and each engine just ignores the one it doesn't
recognize.

Not ported from MUI: `valueLabelDisplay` (a tooltip tracking the thumb's
*exact pixel position* while dragging) and non-linear `scale` functions —
both need real per-frame JS, which crosses the line from "small inline
snippet" into "bespoke JS hook," the thing this library consistently
avoids. The always-visible `label`/current-value header already gives the
same information `valueLabelDisplay="on"` would, without needing to track
the thumb's pixel position at all.

## Forms: `Input` (MUI TextField parity)

`Input.pp_input/1` is modeled on MUI's TextField: three `variant`s
(`outlined`, `filled`, `standard`), a `color` (`primary`/`secondary`/
`tertiary`/`error`) that only shows up on `:focus-within` (border + label),
a `size` (`medium`/`small`), `multiline`+`rows`, and `:start_adornment`/
`:end_adornment` slots. Not ported from MUI: `select` (that's the separate
`PhoenixPaper.Select` component), `fullWidth` (just put `class="w-full"` on
the caller's own wrapper — no component-level attr needed for one utility
class), `margin` (MUI's `dense`/`normal`/`none` vertical-spacing presets —
this library leaves vertical spacing between form fields to the caller's own
layout, same as everywhere else it uses `Stack`/`gap-*` rather than a
per-component margin attr), and controlled/uncontrolled value semantics
(N/A — LiveView forms already have one way to be "controlled": `field=`
from `to_form/2`).

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
full composition example). No `PhoenixPaper.TablePagination`/
`TableSortLabel` — `TableCell`'s `sortable`/`sort_direction` attrs give the
sort-header *look* (a clickable header with a direction arrow), but wiring
an actual sort click to actual reordered data is the caller's LiveView, same
as it would be for a hand-rolled `<th>`; a full pagination component wasn't
built at all (flagged as a bigger, separate addition when this family shipped
— composable from existing `Select`/`Button` pieces, but a real interactive
component with its own API decisions, not just another table part).

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

## Feedback (`Alert`, `Backdrop`, `Dialog`, `Progress`, `Skeleton`, `Snackbar`)

Modeled on MUI's Feedback category. Two things are worth knowing before
touching any of these:

**`Alert`/`Snackbar` needed a new, separate color axis.** Every other
component's `color` attr picks from `primary`/`secondary`/`tertiary`/`error`
— brand/action colors. `Alert`'s `severity` picks from
`success`/`info`/`warning`/`error` — status colors, a different concept that
happens to share the name `error` (and does mean the same red) but has no
brand equivalent for "success" or "info" or "warning". Rather than force
`Alert` onto the existing 4-color scale (which has no green or amber), added
`--color-pp-success`/`-warning`/`-info` (+ `-on-*` pairs) to
`priv/static/phoenix_paper.css`, in both the light (`@theme`) and
`[data-theme="dark"]` blocks — but **not** the `[data-pp-theme="teal"]`
alternate palette, since status colors aren't part of a brand identity swap
and should stay consistent regardless of which brand palette is active. Any
new color token needs adding to `mix.exs`'s `color_classes` list too (see
"`PhoenixPaper.Tails`, not plain `Tails`" above) — these three are as much
a "color token" as `primary`/`secondary`/`tertiary` are, even though they
arrived with a feature addition rather than a new brand color.

**`Dialog` is the one component that isn't stateless-and-simple.** Every
other component in this library either needs no interactivity (most of
them), a tiny bit of pure-CSS trickery (`Drawer`, `Rating`, checkbox/switch
tricks), or genuine server-tracked state as a `Phoenix.LiveComponent`
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
that same shape with Material chrome. The one non-obvious wiring detail:
`data-cancel` has to live on the *outermost* element (the one
`JS.exec("data-cancel", to: "##{id}")` actually targets by CSS selector),
not on the inner `Paper` content — putting it on the wrong element means
`JS.exec` finds nothing and Escape/backdrop-click silently do nothing.

`Progress`'s circular variant is real SVG (`stroke-dasharray`/
`stroke-dashoffset` computed from `value`) only when determinate — the
indeterminate spinner reuses `Button`'s exact bordered-circle
`border-current`/`border-t-transparent`/`animate-spin` trick instead of a
second SVG, since an indeterminate ring doesn't need to represent a real
percentage. `Skeleton`'s `animation="pulse"` is Tailwind's own built-in
`animate-pulse` (nothing to add); `"wave"` needed a real `@keyframes` block
in `priv/static/phoenix_paper.css`, the same as `Progress`'s indeterminate
linear bar — animate-spin/animate-pulse cover the other two, but there's no
built-in Tailwind animation for a sweeping shimmer or a sliding bar.

`Snackbar`'s `anchor_origin` (6 corner/edge positions) and `transition`
(`grow`/`fade`/`slide`/`none`, another set of one-shot `@keyframes`
utilities same as `Skeleton`'s `wave`) came later, matching MUI's own
`Snackbar` page — `transition` only animates the *entrance*; see
`PhoenixPaper.Snackbar`'s moduledoc for why an exit transition,
`autoHideDuration`, and consecutive-snackbar queueing aren't built in (each
needs either the `Dialog`-style always-rendered-plus-`JS` machinery, or
actual state a stateless function component has nowhere to hold).

## Theming

Colors are Tailwind v4 theme tokens backed by CSS custom properties, defined
in `priv/static/phoenix_paper.css`:

- `--color-pp-primary`, `--color-pp-secondary`, `--color-pp-tertiary`,
  `--color-pp-error`, `--color-pp-surface`, `--color-pp-surface-variant`,
  `--color-pp-outline`, and their `pp-on-*` foreground counterparts.
- **Namespaced `pp-` on every token.** This is deliberate: Phoenix apps
  commonly ship daisyUI, which defines its own `primary`/`secondary`/
  `base-100`/... Tailwind v4 theme colors. Unprefixed names would collide
  and whichever stylesheet loads last would silently win. Never add an
  unprefixed color token.
- Dark mode keys off `[data-theme="dark"]` — the same attribute daisyUI and
  Phoenix 1.8's generated `app.css` already use — so PhoenixPaper flips with
  the app's existing toggle instead of adding a second one.
- **"System" default**: when `data-theme` isn't set at all, a
  `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { ... } }`
  block (mirroring `[data-theme="dark"]`'s own values) makes the page follow
  the OS/browser preference automatically — `dev.exs` and any consuming app
  get a correctly-themed first paint with zero clicks. An explicit
  `data-theme="dark"` or `data-theme="light"` always wins over the system
  preference in either direction; the media query is purely the fallback for
  "no explicit choice made yet." `PhoenixPaper.ThemeToggle` (below) is built
  around this: it never forces `data-theme` on mount, only on click.
- A second bundled palette (`teal`/`amber`) is opt-in via
  `data-pp-theme="teal"` on any ancestor element (typically `<html>`).
- **Custom themes**: don't fork the CSS file. Override the `--color-pp-*`
  variables from the consuming app's own stylesheet, after importing
  `phoenix_paper.css`. That's the entire theming API — no build step, no
  JS config.

## `PhoenixPaper.ThemeToggle`, and a `PhoenixPaper.Tails` gap it exposed

Rewritten from a thin `PhoenixPaper.Switch` wrapper to its own markup so a
sun/moon icon could live *inside* the sliding thumb (swapped via a
`peer-checked:` compound selector reaching into the thumb's own children —
`Switch` itself has no attr for that). Two things worth knowing:

- **Deliberately no `pp-*` brand color anywhere in it** (thumb fixed
  white, track a neutral translucent gray) even though `Switch`'s own
  thumb/track go `pp-primary` when checked. A theme toggle's single most
  common home is an `AppBar` header, which is itself very often
  `pp-primary` by default — a `bg-pp-primary` thumb there is the same
  "same color layered on itself" invisibility bug already hit for
  `Drawer`'s colored variants and for buttons dropped into a colored
  `AppBar`. Rather than fix it per-placement (there's no `class` override
  path into `Switch`'s internals anyway), the toggle just never uses a
  color that could plausibly match its own container.
- **Found a real gap in the vendored `Tails`**: passing `class="size-3"`
  to override `PhoenixPaper.Icon`'s default `size-5` left **both** classes
  in the merged output (verified directly: `Tails.classes("size-5
  size-3")` returns `"size-3 size-5"`, not just `"size-3"`) — this
  version of `Tails`'s conflict-resolution ruleset doesn't know about
  Tailwind's `size-*` shorthand (a newer utility; the ruleset predates
  it), so it doesn't treat two `size-*` classes as conflicting the way it
  does e.g. two `text-*` or `bg-*` classes. With both classes present,
  which one actually wins is down to Tailwind's own internal utility
  ordering in the generated stylesheet — not something to rely on. Fixed
  the same way `TableRow`'s `selected` state already does for its own
  specificity fight: `class="!size-3"` (Tailwind's `!important` prefix),
  which wins regardless of generation order. If you hit visibly-wrong
  sizing after overriding an `Icon`'s (or any component's) default size
  via `class`, check whether this is why — `Tails` silently keeping both
  classes doesn't error or warn, it just produces an ambiguous class list.
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

## Elevation

`PhoenixPaper.Elevation.class/1` maps a Material dp level (0-24, clamped) to
a `pp-elevation-N` class. The actual `box-shadow` values live once, in
`priv/static/phoenix_paper.css`, as static `@utility pp-elevation-N` blocks
(a two-layer shadow that approximates — not reproduces exactly — Google's
official umbra/penumbra/ambient elevation table). If pixel-exact MD shadows
are ever needed, replace the CSS values; the Elixir API doesn't change.

## Shape (border radius)

`PhoenixPaper.Shape.class/1,2` maps a token (`:none`, `:xs`, `:sm`, `:md`,
`:lg`, `:xl`, `:full`) to a literal `rounded-*` class, optionally scoped to
an edge (`class(:lg, :top)` → `"rounded-t-lg"`) for shapes like the filled
text field that only round two corners. `Button` (default `:full`, a pill —
Material's spec) and `Card` (default `:lg`) expose a `shape` attr so callers
can override it; components whose radius isn't meant to be tuned per-call
(e.g. `Checkbox`'s box) just call `Shape.class/1,2` internally without
exposing an attr. Add a `shape` attr to a new component only if a caller
overriding it is actually a reasonable thing to want.

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

1. Add `{:phoenix_paper, "~> 0.1"}` to `mix.exs`.
2. In `lib/my_app_web.ex`, add `use PhoenixPaper.Components` to the
   `html_helpers` quote block, next to the existing `core_components` import.
3. In `assets/css/app.css`, after `@import "tailwindcss";`, add:
   ```css
   @import "../../deps/phoenix_paper/priv/static/phoenix_paper.css";
   @source "../../deps/phoenix_paper/lib";
   ```
   The `@source` line is required — without it Tailwind never scans
   PhoenixPaper's `.ex` files and the classes they emit get purged.

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
that points at the real cause, both hit while building `dev.exs`'s catalog:

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

## Dev / live preview

`dev.exs` at the project root is a self-contained script (`Mix.install`,
`path: "."` back to this checkout, `phoenix_playground`, and the real
Tailwind v4 CLI via the `tailwind` hex package — see "Tailwind class
safety" isn't relevant here since it compiles for real, not via a CDN) that
boots a real Phoenix + LiveView server rendering a docs-site catalog: a
left `PhoenixPaper.Drawer` for navigation, a sticky `PhoenixPaper.AppBar`,
and one section per component with a live example, its options, and the
HEEx snippet that produced it. Run it with:

```
elixir dev.exs
```

CSS is compiled once at boot (see the file's own header comment for the
`.dev_tailwind_input.css`/`@source` mechanics — same approach as before,
nothing new there), so a **new** Tailwind class name needs a restart to
show up; structural/logic edits still hot-reload live via
`phoenix_live_reload`. When adding a component, add a section for it here
in the same change — a demo, its `props` list, and a `@<name>_code` module
attribute with the snippet — so the catalog stays complete.

**`hero-*` icon names used anywhere in this file must also be added to
`@demo_icon_css`** (a small hand-rolled `mask-image` rule per icon, right
above `@style_tag` — this script has no real asset pipeline, so it can't
get `hero-*` classes for free from `mix phx.new`'s vendored heroicons the
way a real consuming app does). Forgetting this doesn't error or warn
anywhere — `<.pp_icon name="hero-whatever">` renders a perfectly valid,
empty `<span class="hero-whatever">` with no visual definition at all, so
the icon is just silently invisible. This has happened more than once
(`hero-chevron-right`, `hero-user`, `hero-sun-mini`, `hero-moon-mini` were
all added to component demos before being added here, and stayed
invisible until a user reported it) — when adding a demo that uses an
icon name not already in that list, check it first.

Each section's snippet is hidden behind a "Show code"/"Hide code" toggle
(matching MUI's docs-site pattern), implemented the same CSS-only way as
everything else here: a hidden checkbox, a `<label>`, and the code panel
`<div>` as flat siblings (`peer-*` needs that — see above), all inside
`demo_section/1` in the `PhoenixPaperDemo.UI` module. The label itself has
two child `<span>`s ("▸ Show code" / "▾ Hide code") and swaps which one is
visible via an arbitrary child-selector variant on the *label*, keyed off
its own sibling checkbox —
`peer-checked:[&>.pp-show-code]:hidden peer-checked:[&>.pp-hide-code]:inline`
— rather than the usual pattern of `peer-checked:` toggling a single
sibling's own visibility.

The revealed panel is a plain `<pre><code class="language-elixir">{@code}</code></pre>`
(HEEx-escaped, same as before), colored by **highlight.js** plus its
official **highlightjs-copy** plugin (the "Copy" button) — real, established
JS libraries loaded from cdnjs/jsdelivr in `@hljs_assets`, rather than
building highlighting or a copy button by hand.

Two non-obvious things had to be gotten right for this to actually render
colored, not just plain text with a dark background (which looks *close*
enough to "working" at a glance to be easy to ship broken):

- **Language is `elixir`, not `xml`/`html`,** even though every snippet is
  a HEEx template and looks tag-shaped. HEEx's function-component syntax
  (`<.pp_button ...>`) is not valid XML — a tag name can't start with `.`
  — and highlight.js's strict XML/HTML grammar throws on it per element;
  hljs catches that internally and silently falls back to *plain,
  uncolored* text for that block (still sets `class="hljs"` and
  `data-highlighted="yes"`, so nothing *looks* like an error — it just
  never colors anything). That hit almost every snippet on this page; only
  the couple using bare `<div>`/`<button>` happened to parse as valid XML
  and came out colored. `elixir`'s regex-based lexer doesn't choke on `<`
  or the leading dot — it just treats them as punctuation — so every
  snippet highlights safely, at the cost of not coloring the tags
  themselves as tags (there's no dedicated HEEx grammar to reach for;
  strings/atoms/keywords/numbers still color correctly). `highlight.min.js`'s
  bundled core only ships xml/html/css/js, so the elixir grammar is loaded
  separately from `/languages/elixir.min.js`.
- **The init script must run *after* the `<pre><code>` markup exists in
  the DOM**, not just after the hljs library loads. `@hljs_assets` is
  emitted near the top of the body (next to `@style_tag`), before any code
  panel — a classic (non-async/defer) `<script>` pauses the HTML parser
  and runs immediately at that point in the document, so calling
  `hljs.highlightAll()` directly there finds zero elements every time
  (irrelevant that the whole HTTP response already arrived — the parser
  still walks it as a left-to-right token stream and hasn't built the
  later DOM nodes yet). Wrapping the call in a `DOMContentLoaded` listener
  defers it until parsing has finished the whole document. The `<script
  src>` tags themselves are fine staying where they are — loading the
  libraries early just means they're ready sooner.

`hljs.highlightAll()` runs once, mutating each `<code>`'s DOM (adds
classes, wraps tokens in `<span>`s; the copy plugin inserts a button into
the `<pre>`). That `<pre>` also needs `id={"#{@id}-code"} phx-update="ignore"`
— without it, the flow is: disconnected HTTP render → browser paints plain
text → hljs runs and colors it → LiveSocket connects → LiveView's *first*
connected render has no prior client state to diff against, so it
re-patches the whole page from the server's (unhighlighted) view of the
template, wiping hljs's DOM mutations back to plain text a moment after
they appeared (a visible flash, then revert — the assign-unchanged-means-
untouched optimization only applies to diffs *after* that first connected
patch, not to it). `phx-update="ignore"` tells the client to never patch
that element's subtree at all, at any point, so hljs's mutations are the
only thing that ever touches it. This is the one place this page reaches
an external CDN — see the file's header comment.

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
