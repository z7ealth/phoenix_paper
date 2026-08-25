defmodule PhoenixPaper.ToggleButton do
  @moduledoc """
  A Material Design toggle button (`pp_toggle_button/1`) — a button with a
  boolean `pressed` state, filled when pressed. Combine several inside a
  `PhoenixPaper.ButtonGroup` for a segmented toggle control (e.g. text
  alignment, view mode).
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple, Shape}

  attr(:pressed, :boolean, default: false)
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))

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
    assigns = assign(assigns, :ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <button
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
    """
  end

  defp paper_classes(pressed, color, shape, ripple) do
    [
      "inline-flex items-center justify-center gap-2 border px-4 py-2 text-sm font-medium cursor-pointer transition-colors disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2",
      Shape.class(shape),
      state_classes(pressed, color),
      Ripple.container_classes(ripple)
    ]
  end

  defp state_classes(true, "primary"),
    do: "border-pp-primary bg-pp-primary text-pp-on-primary focus-visible:outline-pp-primary"

  defp state_classes(true, "secondary"),
    do:
      "border-pp-secondary bg-pp-secondary text-pp-on-secondary focus-visible:outline-pp-secondary"

  defp state_classes(true, "tertiary"),
    do: "border-pp-tertiary bg-pp-tertiary text-pp-on-tertiary focus-visible:outline-pp-tertiary"

  defp state_classes(true, "error"),
    do: "border-pp-error bg-pp-error text-pp-on-error focus-visible:outline-pp-error"

  defp state_classes(false, "primary"),
    do:
      "border-pp-outline text-pp-on-surface hover:bg-pp-primary/10 focus-visible:outline-pp-primary"

  defp state_classes(false, "secondary"),
    do:
      "border-pp-outline text-pp-on-surface hover:bg-pp-secondary/10 focus-visible:outline-pp-secondary"

  defp state_classes(false, "tertiary"),
    do:
      "border-pp-outline text-pp-on-surface hover:bg-pp-tertiary/10 focus-visible:outline-pp-tertiary"

  defp state_classes(false, "error"),
    do: "border-pp-outline text-pp-on-surface hover:bg-pp-error/10 focus-visible:outline-pp-error"
end
