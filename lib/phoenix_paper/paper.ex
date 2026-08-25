defmodule PhoenixPaper.Paper do
  @moduledoc """
  The base Material surface (`pp_paper/1`) — a background, an elevation
  shadow, and rounded corners. No padding, no title/actions slots; it's the
  primitive `PhoenixPaper.Card` is built on top of, for anything that just
  needs a raised surface to sit on.

      <.pp_paper elevation={2} class="p-4">
        Anything can go here.
      </.pp_paper>
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers, Shape}

  attr(:elevation, :integer, default: 1)

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
      class={Helpers.classes(@paperize, paper_classes(@elevation, @shape), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(elevation, shape) do
    ["block bg-pp-surface text-pp-on-surface", Shape.class(shape), Elevation.class(elevation)]
  end
end
