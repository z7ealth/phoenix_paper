defmodule PhoenixPaper.ImageList do
  @moduledoc """
  A grid gallery of images (`pp_image_list/1`), in the spirit of MUI's
  [`ImageList`](https://mui.com/material-ui/react-image-list/) (the
  `standard` variant — masonry/quilted/woven layouts aren't implemented).
  Pair with `PhoenixPaper.ImageListItem`:

      <.pp_image_list cols={3}>
        <.pp_image_list_item src="/images/1.jpg" title="Breakfast" />
        <.pp_image_list_item src="/images/2.jpg" title="Burger" subtitle="Restaurant" />
      </.pp_image_list>
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Spacing}

  attr(:cols, :integer, default: 3, values: [1, 2, 3, 4, 5, 6])
  attr(:spacing, :atom, default: :xs, values: ~w(none xs sm md lg xl 2xl)a)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders an image grid. See the module doc."
  def pp_image_list(assigns) do
    ~H"""
    <div
      data-pp-component="image-list"
      class={Helpers.classes(@paperize, paper_classes(@cols, @spacing), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(cols, spacing) do
    ["grid", cols_class(cols), Spacing.gap(spacing)]
  end

  defp cols_class(1), do: "grid-cols-1"
  defp cols_class(2), do: "grid-cols-2"
  defp cols_class(3), do: "grid-cols-3"
  defp cols_class(4), do: "grid-cols-4"
  defp cols_class(5), do: "grid-cols-5"
  defp cols_class(6), do: "grid-cols-6"
end
