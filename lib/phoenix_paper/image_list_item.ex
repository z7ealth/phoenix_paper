defmodule PhoenixPaper.ImageListItem do
  @moduledoc """
  A single tile (`pp_image_list_item/1`) inside `PhoenixPaper.ImageList`, in
  the spirit of MUI's `ImageListItem` + `ImageListItemBar` combined — an
  image with an optional title/subtitle overlay bar along the bottom edge.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Shape}

  attr(:src, :string, required: true)
  attr(:alt, :string, default: "")
  attr(:title, :string, default: nil)
  attr(:subtitle, :string, default: nil)

  attr(:shape, :atom,
    default: :lg,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders one image tile. See the module doc."
  def pp_image_list_item(assigns) do
    ~H"""
    <div
      data-pp-component="image-list-item"
      class={Helpers.classes(@paperize, paper_classes(@shape), @class)}
      {@rest}
    >
      <img src={@src} alt={@alt} class="aspect-square h-full w-full object-cover" />
      <div
        :if={@title}
        class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/70 to-transparent px-3 py-2 text-white"
      >
        <p class="truncate text-sm font-medium">{@title}</p>
        <p :if={@subtitle} class="truncate text-xs opacity-80">{@subtitle}</p>
      </div>
    </div>
    """
  end

  defp paper_classes(shape) do
    ["relative overflow-hidden", Shape.class(shape)]
  end
end
