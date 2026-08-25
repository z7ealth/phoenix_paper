defmodule PhoenixPaper.Fab do
  @moduledoc """
  A Material Design Floating Action Button (`pp_fab/1`) — a circular,
  elevated, icon-only button, or (with `extended`) a pill with a label.
  Typically anchored to a screen corner by the caller (e.g. `class="fixed
  bottom-6 right-6"`).
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers, Ripple}

  attr(:color, :string, default: "secondary", values: ~w(primary secondary tertiary error))
  attr(:size, :string, default: "md", values: ~w(sm md lg))
  attr(:extended, :boolean, default: false)

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

  @doc "Renders a floating action button. See the module doc."
  def pp_fab(assigns) do
    assigns = assign(assigns, :ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <button
      type={@type}
      disabled={@disabled}
      data-pp-component="fab"
      class={Helpers.classes(@paperize, paper_classes(@color, @size, @extended, @ripple?), @class)}
      onclick={Ripple.on_click(@ripple?)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp paper_classes(color, size, extended, ripple) do
    [
      base_classes(extended),
      size_classes(size, extended),
      color_classes(color),
      Elevation.class(6),
      Ripple.container_classes(ripple)
    ]
  end

  defp base_classes(true) do
    "inline-flex items-center gap-2 rounded-full font-medium uppercase tracking-wide cursor-pointer transition-shadow hover:pp-elevation-8 disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
  end

  defp base_classes(false) do
    "inline-flex items-center justify-center rounded-full cursor-pointer transition-shadow hover:pp-elevation-8 disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
  end

  defp size_classes("sm", false), do: "size-10"
  defp size_classes("md", false), do: "size-14"
  defp size_classes("lg", false), do: "size-16"
  defp size_classes("sm", true), do: "h-10 px-4 text-xs"
  defp size_classes("md", true), do: "h-14 px-6 text-sm"
  defp size_classes("lg", true), do: "h-16 px-8 text-base"

  defp color_classes("primary"),
    do: "bg-pp-primary text-pp-on-primary focus-visible:outline-pp-primary"

  defp color_classes("secondary"),
    do: "bg-pp-secondary text-pp-on-secondary focus-visible:outline-pp-secondary"

  defp color_classes("tertiary"),
    do: "bg-pp-tertiary text-pp-on-tertiary focus-visible:outline-pp-tertiary"

  defp color_classes("error"), do: "bg-pp-error text-pp-on-error focus-visible:outline-pp-error"
end
