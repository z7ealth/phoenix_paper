defmodule PhoenixPaper.Grid do
  @moduledoc """
  A 12-column CSS grid container (`pp_grid/1`), in the spirit of MUI's
  [`Grid`](https://mui.com/material-ui/react-grid/) `container`. Pair with
  `PhoenixPaper.GridItem` for each column-spanning child:

      <.pp_grid spacing={:md}>
        <.pp_grid_item span={12} md={4}>Sidebar</.pp_grid_item>
        <.pp_grid_item span={12} md={8}>Content</.pp_grid_item>
      </.pp_grid>
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Spacing}

  attr(:spacing, :atom, default: :md, values: ~w(none xs sm md lg xl 2xl)a)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a grid container. See the module doc."
  def pp_grid(assigns) do
    ~H"""
    <div
      data-pp-component="grid"
      class={Helpers.classes(@paperize, paper_classes(@spacing), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(spacing) do
    ["grid grid-cols-12", Spacing.gap(spacing)]
  end
end
