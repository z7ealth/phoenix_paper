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
  `Autocomplete`, `TransferList`, `Navbar`, `Drawer`, `List`, `ListItem`,
  `ListSubheader`, `Divider`, `Box`, `Container`, `Stack`, `Grid`,
  `GridItem`, `ImageList`, `ImageListItem`, ...), plus `Helpers`,
  `Elevation`, `Spacing`, `Shape`, `Ripple`.
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
  typography. A caller-supplied `class` is still merged on top via `Tails`
  (last conflicting utility wins), so small tweaks don't require dropping
  into `paperize={false}`.
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
inside `Navbar`, nowhere near the drawer): a plain `<label for={checkbox_id}>`
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
- A second bundled palette (`teal`/`amber`) is opt-in via
  `data-pp-theme="teal"` on any ancestor element (typically `<html>`).
- **Custom themes**: don't fork the CSS file. Override the `--color-pp-*`
  variables from the consuming app's own stylesheet, after importing
  `phoenix_paper.css`. That's the entire theming API — no build step, no
  JS config.

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

## Tailwind/Phoenix version note

`priv/static/phoenix_paper.css` uses Tailwind v4 syntax (`@theme`,
`@utility`, `@source`) and assumes a Phoenix 1.7+ app (vendored heroicons).
There is currently no separate dev/preview environment in this repo — verify
component changes by writing/running the `test/phoenix_paper/*_test.exs`
suite (`mix test`), or by wiring this checkout into a real Phoenix app as a
`path:` dependency per "Consumer setup" above.

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
