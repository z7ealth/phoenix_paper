defmodule PhoenixPaper.Paper do
  @moduledoc """
  The base Material surface (`pp_paper/1`) — a background, an elevation
  shadow, and rounded corners. No padding, no title/actions slots; it's the
  primitive `PhoenixPaper.Card` is built on top of, for anything that just
  needs a raised surface to sit on.

      <.pp_paper elevation={2} class="p-4">
        Anything can go here.
      </.pp_paper>

  In dark mode a shadow on a dark page doesn't show, so the surface also
  gets *lighter* as `elevation` goes up (MUI's approach): the
  `pp-surface-overlay` utility layers a translucent white tint whose
  opacity each `pp-elevation-N` class sets (see `phoenix_paper.css`). In
  light mode the tint is transparent, so nothing changes there.
  `elevation={0}` gets no tint at all.

  `color` (`"surface"` default, or `"primary"`/`"secondary"`/`"accent"`/
  `"error"`) picks the background/foreground pair — `bg-pp-primary
  text-pp-on-primary`, ... A component that needs a colored surface
  (`PhoenixPaper.Accordion`'s filled variants) passes it here rather than
  overriding `bg-pp-surface` through `class`, which PhoenixPaper doesn't
  merge (see AGENTS.md).
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers, Shape}

  attr(:elevation, :integer, default: 1)

  attr(:color, :string,
    default: "surface",
    values: ~w(surface primary secondary accent error),
    doc: "background/foreground pair; surface is the neutral default"
  )

  attr(:shape, :atom,
    default: :lg,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  attr(:component, :string,
    default: "paper",
    doc:
      "overrides the data-pp-component marker — used by components (e.g. Card) built on top of Paper"
  )

  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a surface. See the module doc."
  def pp_paper(assigns) do
    ~H"""
    <div
      data-pp-component={@component}
      class={Helpers.classes(@paperize, paper_classes(@elevation, @shape, @color), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(elevation, shape, color) do
    [
      "block pp-surface-overlay",
      color_classes(color),
      Shape.class(shape),
      Elevation.class(elevation)
    ]
  end

  defp color_classes("surface"), do: "bg-pp-surface text-pp-on-surface"
  defp color_classes("primary"), do: "bg-pp-primary text-pp-on-primary"
  defp color_classes("secondary"), do: "bg-pp-secondary text-pp-on-secondary"
  defp color_classes("accent"), do: "bg-pp-accent text-pp-on-accent"
  defp color_classes("error"), do: "bg-pp-error text-pp-on-error"
end
