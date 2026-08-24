defmodule PhoenixPaper.Button do
  @moduledoc """
  A Material Design button (`pp_button/1`).

  Supports the five classic Material button variants: `raised`, `flat`,
  `outlined`, `text` and `icon`. Ripples on click/tap by default — see
  `PhoenixPaper.Ripple`, and `AGENTS.md` for the `paperize` contract shared
  by every PhoenixPaper component.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers, Ripple, Shape}

  attr(:paperize, :boolean, default: true, doc: "apply PhoenixPaper's Material styling")
  attr(:variant, :string, default: "raised", values: ~w(raised flat outlined text icon))
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))
  attr(:elevation, :integer, default: nil, doc: "override the resting elevation (0-24)")

  attr(:shape, :atom,
    default: :full,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:ripple, :boolean, default: true, doc: "the Material ripple effect on click/tap")
  attr(:disabled, :boolean, default: false)
  attr(:type, :string, default: "button", values: ~w(button submit reset))
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form name value autofocus))

  slot(:inner_block, required: true)

  @doc "Renders a button. See the module doc for variants and colors."
  def pp_button(assigns) do
    ~H"""
    <button
      type={@type}
      disabled={@disabled}
      data-pp-component="button"
      data-pp-variant={@variant}
      class={Helpers.classes(@paperize, paper_classes(@variant, @color, @elevation, @shape, @ripple), @class)}
      onclick={Ripple.on_click(@ripple)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp paper_classes(variant, color, elevation, shape, ripple) do
    [
      base_classes(variant),
      Shape.class(shape),
      color_classes(variant, color),
      elevation_classes(variant, elevation),
      Ripple.container_classes(ripple)
    ]
  end

  defp base_classes("icon") do
    "inline-flex items-center justify-center p-2 cursor-pointer transition-colors duration-150 ease-out select-none disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
  end

  defp base_classes(_variant) do
    "inline-flex items-center justify-center gap-2 px-6 py-2.5 text-sm font-medium tracking-wide uppercase whitespace-nowrap cursor-pointer transition-[box-shadow,background-color,color,border-color] duration-150 ease-out select-none disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
  end

  defp color_classes("raised", "primary"),
    do: "bg-pp-primary text-pp-on-primary focus-visible:outline-pp-primary"

  defp color_classes("raised", "secondary"),
    do: "bg-pp-secondary text-pp-on-secondary focus-visible:outline-pp-secondary"

  defp color_classes("raised", "tertiary"),
    do: "bg-pp-tertiary text-pp-on-tertiary focus-visible:outline-pp-tertiary"

  defp color_classes("raised", "error"),
    do: "bg-pp-error text-pp-on-error focus-visible:outline-pp-error"

  defp color_classes("flat", "primary"),
    do: "bg-pp-primary text-pp-on-primary focus-visible:outline-pp-primary"

  defp color_classes("flat", "secondary"),
    do: "bg-pp-secondary text-pp-on-secondary focus-visible:outline-pp-secondary"

  defp color_classes("flat", "tertiary"),
    do: "bg-pp-tertiary text-pp-on-tertiary focus-visible:outline-pp-tertiary"

  defp color_classes("flat", "error"),
    do: "bg-pp-error text-pp-on-error focus-visible:outline-pp-error"

  defp color_classes("outlined", "primary"),
    do:
      "bg-transparent text-pp-primary border border-pp-primary hover:bg-pp-primary/10 focus-visible:outline-pp-primary"

  defp color_classes("outlined", "secondary"),
    do:
      "bg-transparent text-pp-secondary border border-pp-secondary hover:bg-pp-secondary/10 focus-visible:outline-pp-secondary"

  defp color_classes("outlined", "tertiary"),
    do:
      "bg-transparent text-pp-tertiary border border-pp-tertiary hover:bg-pp-tertiary/10 focus-visible:outline-pp-tertiary"

  defp color_classes("outlined", "error"),
    do:
      "bg-transparent text-pp-error border border-pp-error hover:bg-pp-error/10 focus-visible:outline-pp-error"

  defp color_classes("text", "primary"),
    do: "bg-transparent text-pp-primary hover:bg-pp-primary/10 focus-visible:outline-pp-primary"

  defp color_classes("text", "secondary"),
    do:
      "bg-transparent text-pp-secondary hover:bg-pp-secondary/10 focus-visible:outline-pp-secondary"

  defp color_classes("text", "tertiary"),
    do:
      "bg-transparent text-pp-tertiary hover:bg-pp-tertiary/10 focus-visible:outline-pp-tertiary"

  defp color_classes("text", "error"),
    do: "bg-transparent text-pp-error hover:bg-pp-error/10 focus-visible:outline-pp-error"

  defp color_classes("icon", "primary"),
    do: "text-pp-primary hover:bg-pp-primary/10 focus-visible:outline-pp-primary"

  defp color_classes("icon", "secondary"),
    do: "text-pp-secondary hover:bg-pp-secondary/10 focus-visible:outline-pp-secondary"

  defp color_classes("icon", "tertiary"),
    do: "text-pp-tertiary hover:bg-pp-tertiary/10 focus-visible:outline-pp-tertiary"

  defp color_classes("icon", "error"),
    do: "text-pp-error hover:bg-pp-error/10 focus-visible:outline-pp-error"

  # Default elevation is only animated (hover boost) when the caller hasn't
  # pinned an explicit level — see the "Tailwind class safety" note in
  # AGENTS.md for why this is two literal branches instead of interpolation.
  defp elevation_classes("raised", nil), do: "pp-elevation-2 hover:pp-elevation-4"
  defp elevation_classes("raised", level), do: Elevation.class(level)
  defp elevation_classes(_variant, nil), do: ""
  defp elevation_classes(_variant, level), do: Elevation.class(level)
end
