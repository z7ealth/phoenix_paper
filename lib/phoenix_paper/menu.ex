defmodule PhoenixPaper.Menu do
  @moduledoc """
  A trigger that opens a small anchored popover list of actions
  (`pp_menu/1`), in the spirit of MUI's `Menu`/`MenuItem`
  (mui.com/material-ui/react-menu/) — an overflow ("...") menu, a profile
  menu, anything where clicking a button reveals a short list of things to
  do next.

      <.pp_menu id="profile-menu">
        <:trigger><.pp_icon name="hero-ellipsis-vertical" /></:trigger>
        <.pp_list>
          <.pp_list_item navigate={~p"/profile"}>Profile</.pp_list_item>
          <.pp_list_item navigate={~p"/settings"}>Settings</.pp_list_item>
          <.pp_list_item phx-click="log_out">Log out</.pp_list_item>
        </.pp_list>
      </.pp_menu>

  `:inner_block` is opaque content, same as `PhoenixPaper.Dialog`'s body —
  typically a `PhoenixPaper.List` of `PhoenixPaper.ListItem`s (already
  styled for a clickable row with hover/active states and link-or-button
  dispatch, the same reasoning `ListItem`'s own moduledoc gives for reuse
  "standalone, e.g. inside a Card" — a menu item is just another place a
  styled list item is useful on its own), but any content works.

  ## Why this isn't the checkbox/`peer-checked:` trick

  Every other reveal-on-interaction component in this library
  (`Accordion`, `Drawer`, `SpeedDial`, `Checkbox`/`Switch`/`RadioGroup`'s
  own state styling) is pure CSS: a hidden checkbox plus `peer-checked:`/
  `has-[:checked]:`. That trick can only express "is *some* sibling
  checked" — it has no way to close itself when the user clicks an item
  inside the popover or clicks anywhere else on the page, both of which
  are baseline expected behavior for a menu (MUI's own `Menu` does both).
  Detecting "a click happened outside this element" needs actual JS, so
  `pp_menu/1` is built the same way `PhoenixPaper.Dialog` is — the other
  component in this library that isn't stateless-and-simple — with plain
  `Phoenix.LiveView.JS` commands (`JS.toggle`/`JS.hide`/
  `JS.toggle_attribute`) and LiveView's built-in `phx-click-away` binding,
  not a custom hook.

  Unlike `Dialog`, the trigger and the popover panel are rendered by this
  *same* component rather than the trigger living wherever the caller puts
  it (`Dialog.show/2` is called from a button anywhere on the page) — a
  menu's popover has to be positioned right under its own trigger, and the
  only way to do that without a JS hook measuring `getBoundingClientRect`
  (the "bespoke JS hook" this library consistently avoids — see
  `PhoenixPaper.Slider`'s `valueLabelDisplay`/`PhoenixPaper.Tabs`'s
  sliding-indicator moduledoc notes for the same trade-off elsewhere) is
  plain CSS: `absolute`-position the panel against a `relative` wrapper
  that also contains the trigger. That means trigger and panel can't be
  decoupled the way `Dialog`'s are.

  ## Closing behavior

  - **Clicking the trigger again** toggles it via `phx-click={toggle(@id)}`.
  - **Clicking anywhere inside the panel** closes it — a plain
    `phx-click={close(@id)}` on the panel itself, relying on the native
    DOM click bubbling from whatever item was actually clicked up to this
    listener, *after* that item's own `phx-click`/`JS` (if any) already
    ran. This is what closes the menu after picking an item, with zero
    cooperation needed from whatever `inner_block` renders — a plain `<a>`,
    a `ListItem`, a raw `<button>`, all bubble the same way. The one thing
    this can't support is an item meant to stay open after its own click
    (e.g. a submenu trigger, or a `Switch` toggled from inside the menu) —
    not handled here, same class of gap `Accordion`'s one-way radio close
    or `Tabs`' non-roving focus already document as a known, accepted
    limitation rather than a bug to chase.
  - **Clicking outside** closes it via `phx-click-away` (the same LiveView
    binding `PhoenixPaper.Dialog`'s focus-trap container uses for its
    backdrop-click case).
  - **Escape** closes it via `phx-window-keydown`/`phx-key="escape"`, again
    matching `Dialog`.

  No focus trapping (`Dialog`'s `focus_wrap/1`) and no roving
  `tabindex`/arrow-key item navigation like MUI's real `Menu` — tab order
  moves through whatever `inner_block` renders in normal document order,
  the same simplification `Tabs` makes for its own tablist.

  ## `paperize`

  `paperize={false}` drops the popover's `PhoenixPaper.Paper` surface (its
  background/elevation/rounded corners) and its cosmetic sizing, same as
  everywhere else — but the panel's `absolute`/anchor-offset positioning
  stays unconditional. `paperize` is also passed on to the trigger
  `pp_button`, so `paperize={false}` gives an unstyled trigger too (style
  it with `trigger_class`); the `trigger_variant="none"` button keeps its
  `cursor-pointer` either way. That positioning
  is plumbing the popover can't work without (without it the panel would
  render in normal document flow instead of anchored under its trigger),
  not part of the visual skin — the same reasoning `PhoenixPaper.Badge`'s
  wrapping `<span>` and `PhoenixPaper.Autocomplete`'s anchor `<div>` give
  for their own hardcoded structural classes (see AGENTS.md, "The
  `paperize` contract").

  ## The trigger

  The trigger is a real `PhoenixPaper.Button`, so it looks and behaves
  like every other button (hover tint, focus ring, ripple) with no custom
  CSS. `:trigger` is only its content — an icon or a label — and
  `trigger_variant`/`trigger_color`/`trigger_size` (plus `trigger_class`)
  pass straight through to that button:

      <.pp_menu id="row-menu">
        <:trigger><.pp_icon name="hero-ellipsis-vertical" /></:trigger>
        ...
      </.pp_menu>

      <.pp_menu id="export-menu" trigger_variant="outlined">
        <:trigger>Export <.pp_icon name="hero-chevron-down-mini" /></:trigger>
        ...
      </.pp_menu>

  `trigger_variant` defaults to `"icon"` (the overflow-"⋮" case); any
  `pp_button` variant works. Inside a colored `PhoenixPaper.AppBar` use
  `trigger_color="inherit"` so the trigger doesn't vanish into the bar.
  `trigger_variant="none"` renders a bare, unstyled `<button>` (only
  `cursor-pointer`) for a fully custom trigger. Never put your own button
  or link inside `:trigger` — it's already rendered inside one, and a
  button inside a button is invalid HTML.

  ## `anchor`

  `"bottom-start"` (default), `"bottom-end"`, `"top-start"`, `"top-end"` —
  a fixed corner/offset relative to the trigger, the same "no collision
  detection/auto-flip like MUI's Popper-based positioning" trade-off
  `PhoenixPaper.Tooltip`'s `placement` already documents, for the same
  reason: real auto-flip needs to measure available viewport space at
  runtime, which is a JS hook this library doesn't add.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.Helpers

  import PhoenixPaper.Paper, only: [pp_paper: 1]
  import PhoenixPaper.Button, only: [pp_button: 1]

  attr(:id, :string, required: true)

  attr(:anchor, :string,
    default: "bottom-start",
    values: ~w(bottom-start bottom-end top-start top-end),
    doc: "fixed corner/offset the panel opens from, relative to the trigger"
  )

  attr(:elevation, :integer, default: 8)

  attr(:shape, :atom,
    default: :sm,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:trigger_variant, :string,
    default: "icon",
    values: ~w(icon text outlined raised flat none),
    doc: "the trigger pp_button's variant; none = bare unstyled button"
  )

  attr(:trigger_color, :string,
    default: "primary",
    values: ~w(primary secondary accent error inherit),
    doc: "the trigger pp_button's color"
  )

  attr(:trigger_size, :string,
    default: "medium",
    values: ~w(small medium large),
    doc: "the trigger pp_button's size"
  )

  attr(:trigger_class, :any, default: nil, doc: "extra classes for the trigger button")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:trigger,
    required: true,
    doc: "the trigger button's content (an icon or label) — not a button itself"
  )

  slot(:inner_block, required: true, doc: "the popover's content, typically a PhoenixPaper.List")

  @doc "Renders a menu trigger and its popover. See the module doc."
  def pp_menu(assigns) do
    ~H"""
    <div class="relative inline-block" data-pp-component="menu">
      <button
        :if={@trigger_variant == "none"}
        type="button"
        id={"#{@id}-trigger"}
        aria-haspopup="true"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-click={toggle(@id)}
        class={["cursor-pointer", @trigger_class]}
      >
        {render_slot(@trigger)}
      </button>
      <.pp_button
        :if={@trigger_variant != "none"}
        id={"#{@id}-trigger"}
        variant={@trigger_variant}
        color={@trigger_color}
        size={@trigger_size}
        paperize={@paperize}
        class={@trigger_class}
        aria-haspopup="true"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-click={toggle(@id)}
      >
        {render_slot(@trigger)}
      </.pp_button>
      <div
        id={"#{@id}-panel"}
        phx-click-away={close(@id)}
        phx-window-keydown={close(@id)}
        phx-key="escape"
        phx-click={close(@id)}
        role="menu"
        aria-labelledby={"#{@id}-trigger"}
        class={["absolute z-40 hidden", anchor_classes(@anchor)]}
      >
        <.pp_paper
          elevation={@elevation}
          shape={@shape}
          paperize={@paperize}
          component="menu-panel"
          class={Helpers.classes(@paperize, "min-w-[180px] py-2", @class)}
          {@rest}
        >
          {render_slot(@inner_block)}
        </.pp_paper>
      </div>
    </div>
    """
  end

  @doc """
  A `Phoenix.LiveView.JS` command that opens/closes the menu with `id` —
  wired automatically to the trigger button; expose it if something else
  on the page should also toggle this menu.
  """
  def toggle(js \\ %JS{}, id) do
    js
    |> JS.toggle(to: "##{id}-panel", display: "block")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id}-trigger")
  end

  @doc "A `Phoenix.LiveView.JS` command that closes the menu with `id`."
  def close(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}-panel")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}-trigger")
  end

  defp anchor_classes("bottom-start"), do: "top-full left-0 mt-1"
  defp anchor_classes("bottom-end"), do: "top-full right-0 mt-1"
  defp anchor_classes("top-start"), do: "bottom-full left-0 mb-1"
  defp anchor_classes("top-end"), do: "bottom-full right-0 mb-1"
end
