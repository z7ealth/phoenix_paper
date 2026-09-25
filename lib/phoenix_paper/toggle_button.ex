defmodule PhoenixPaper.ToggleButton do
  @moduledoc """
  A Material Design toggle button (`pp_toggle_button/1`) — a button with a
  boolean `pressed` state, filled when pressed. Combine several inside a
  `PhoenixPaper.ButtonGroup` for a segmented toggle control (e.g. text
  alignment, view mode).

  ## Controlled (default)

  Like MUI's `ToggleButton` with `selected` + `onChange`: the look comes
  from `pressed` alone, and clicking does nothing but fire whatever
  `phx-click` you pass. Your LiveView owns the state and re-renders:

      <.pp_toggle_button
        pressed={"bold" in @formats}
        phx-click="toggle_format"
        phx-value-format="bold"
      >
        Bold
      </.pp_toggle_button>

  Use this when the pressed state is app state (a filter, a view mode the
  server acts on, a form value).

  ## Client-side (`toggle`)

  For pure-UI toggles the server doesn't need to know about, `toggle`
  makes the button flip itself on click, with no round trip. `pressed`
  becomes the initial state:

      <.pp_toggle_button toggle pressed>Bold</.pp_toggle_button>
      <.pp_toggle_button toggle>Italic</.pp_toggle_button>

  `toggle_group` makes a set exclusive, like radio buttons: clicking one
  presses it and un-presses every other button with the same group name.
  Clicking the pressed one leaves it pressed, so one is always selected:

      <.pp_button_group>
        <.pp_toggle_button toggle_group="view" pressed>Columns</.pp_toggle_button>
        <.pp_toggle_button toggle_group="view">Grid</.pp_toggle_button>
        <.pp_toggle_button toggle_group="view">Group</.pp_toggle_button>
      </.pp_button_group>

  `toggle_group` implies `toggle`. Group names are page-wide, so keep them
  unique per set.

  How it works: the click runs `Phoenix.LiveView.JS` commands
  (`JS.toggle_attribute({"aria-pressed", "true", "false"})`, or
  `JS.set_attribute` across the group), and the pressed look is styled off
  `aria-pressed` itself (`aria-pressed:bg-pp-primary`, ...) instead of the
  `pressed` attr. JS commands rather than a plain `onclick` on purpose:
  LiveView keeps attributes set by JS commands across later re-renders,
  where an `onclick`'s `setAttribute` would be reset to the server's value
  on the next patch. That also means `toggle` needs LiveView's JS client
  on the page: any LiveView, or a plain controller-rendered page that
  loads `app.js` with its `LiveSocket` (the commands run client-side, even
  before or without a socket connection).

  `on_toggle` (a `JS`) runs after the flip, e.g.
  `on_toggle={JS.push("format_changed")}` if you do want to tell the
  server; `phx-value-*` attrs on the button ride along with the push. In
  `toggle` mode use `on_toggle` rather than `phx-click`, which the
  built-in commands already occupy.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Ripple, Shape}

  attr(:pressed, :boolean,
    default: false,
    doc: "the pressed state — or, with toggle, the initial pressed state"
  )

  attr(:toggle, :boolean,
    default: false,
    doc: "flip pressed client-side on click, no server round trip"
  )

  attr(:toggle_group, :string,
    default: nil,
    doc: "exclusive client-side group: pressing one un-presses the rest (implies toggle)"
  )

  attr(:on_toggle, JS, default: %JS{}, doc: "toggle mode only: JS commands run after the flip")

  attr(:color, :string, default: "primary", values: ~w(primary secondary accent error))

  attr(:shape, :atom,
    default: :md,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:ripple, :boolean,
    default: true,
    doc:
      "the Material ripple effect on click/tap — off whenever paperize is false, see PhoenixPaper.Ripple"
  )

  attr(:disabled, :boolean, default: false)
  attr(:type, :string, default: "button", values: ~w(button submit reset))
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form name value phx-click))

  slot(:inner_block, required: true)

  @doc "Renders a toggle button. See the module doc."
  def pp_toggle_button(assigns) do
    assigns =
      assigns
      |> assign(:ripple?, assigns.ripple and assigns.paperize)
      |> assign(:toggle?, assigns.toggle or assigns.toggle_group != nil)

    ~H"""
    <button
      :if={!@toggle?}
      type={@type}
      disabled={@disabled}
      aria-pressed={to_string(@pressed)}
      data-pp-component="toggle-button"
      class={Helpers.classes(@paperize, paper_classes(@pressed, @color, @shape, @ripple?), @class)}
      onclick={Ripple.on_click(@ripple?)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    <button
      :if={@toggle?}
      type={@type}
      disabled={@disabled}
      aria-pressed={to_string(@pressed)}
      data-pp-component="toggle-button"
      data-pp-toggle-group={@toggle_group}
      class={Helpers.classes(@paperize, toggle_paper_classes(@color, @shape, @ripple?), @class)}
      onclick={Ripple.on_click(@ripple?)}
      phx-click={toggle_js(@toggle_group, @on_toggle)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc false
  def toggle_js(nil, %JS{ops: extra}) do
    %JS{ops: JS.toggle_attribute({"aria-pressed", "true", "false"}).ops ++ extra}
  end

  def toggle_js(group, %JS{ops: extra}) do
    ops =
      {"aria-pressed", "false"}
      |> JS.set_attribute(to: ~s([data-pp-toggle-group="#{group}"]))
      |> JS.set_attribute({"aria-pressed", "true"})

    %JS{ops: ops.ops ++ extra}
  end

  defp base_classes do
    "inline-flex items-center justify-center gap-2 border px-4 py-2 text-sm font-medium cursor-pointer transition-colors disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
  end

  defp paper_classes(pressed, color, shape, ripple) do
    [
      base_classes(),
      Shape.class(shape),
      state_classes(pressed, color),
      Ripple.container_classes(ripple)
    ]
  end

  # Toggle mode can't know the pressed state at render time (the client
  # owns it), so both looks are always present: the unpressed classes as
  # the base, the pressed ones behind `aria-pressed:`. The pressed hover is
  # pinned with `aria-pressed:hover:` (higher specificity) so the unpressed
  # `hover:` tint can't win on a pressed button.
  defp toggle_paper_classes(color, shape, ripple) do
    [
      base_classes(),
      Shape.class(shape),
      toggle_state_classes(color),
      Ripple.container_classes(ripple)
    ]
  end

  defp state_classes(true, "primary"),
    do: "border-pp-primary bg-pp-primary text-pp-on-primary focus-visible:outline-pp-primary"

  defp state_classes(true, "secondary"),
    do:
      "border-pp-secondary bg-pp-secondary text-pp-on-secondary focus-visible:outline-pp-secondary"

  defp state_classes(true, "accent"),
    do: "border-pp-accent bg-pp-accent text-pp-on-accent focus-visible:outline-pp-accent"

  defp state_classes(true, "error"),
    do: "border-pp-error bg-pp-error text-pp-on-error focus-visible:outline-pp-error"

  defp state_classes(false, "primary"),
    do:
      "border-pp-outline text-pp-on-surface hover:bg-pp-primary/10 focus-visible:outline-pp-primary"

  defp state_classes(false, "secondary"),
    do:
      "border-pp-outline text-pp-on-surface hover:bg-pp-secondary/10 focus-visible:outline-pp-secondary"

  defp state_classes(false, "accent"),
    do:
      "border-pp-outline text-pp-on-surface hover:bg-pp-accent/10 focus-visible:outline-pp-accent"

  defp state_classes(false, "error"),
    do: "border-pp-outline text-pp-on-surface hover:bg-pp-error/10 focus-visible:outline-pp-error"

  defp toggle_state_classes("primary"),
    do:
      "border-pp-outline text-pp-on-surface hover:bg-pp-primary/10 focus-visible:outline-pp-primary aria-pressed:border-pp-primary aria-pressed:bg-pp-primary aria-pressed:text-pp-on-primary aria-pressed:hover:bg-pp-primary"

  defp toggle_state_classes("secondary"),
    do:
      "border-pp-outline text-pp-on-surface hover:bg-pp-secondary/10 focus-visible:outline-pp-secondary aria-pressed:border-pp-secondary aria-pressed:bg-pp-secondary aria-pressed:text-pp-on-secondary aria-pressed:hover:bg-pp-secondary"

  defp toggle_state_classes("accent"),
    do:
      "border-pp-outline text-pp-on-surface hover:bg-pp-accent/10 focus-visible:outline-pp-accent aria-pressed:border-pp-accent aria-pressed:bg-pp-accent aria-pressed:text-pp-on-accent aria-pressed:hover:bg-pp-accent"

  defp toggle_state_classes("error"),
    do:
      "border-pp-outline text-pp-on-surface hover:bg-pp-error/10 focus-visible:outline-pp-error aria-pressed:border-pp-error aria-pressed:bg-pp-error aria-pressed:text-pp-on-error aria-pressed:hover:bg-pp-error"
end
