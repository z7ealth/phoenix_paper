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
  `GridItem`, `ImageList`, `ImageListItem`, `Paper`, `Typography`, `Table`,
  `TableContainer`, `TableHead`, `TableBody`, `TableRow`, `TableCell`,
  `TableFooter`, ...), plus `Helpers`, `Elevation`, `Spacing`, `Shape`,
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
left `PhoenixPaper.Drawer` for navigation, a sticky `PhoenixPaper.Navbar`,
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
