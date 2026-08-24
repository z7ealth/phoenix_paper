defmodule PhoenixPaper.Container do
  @moduledoc """
  A centered, width-constrained content wrapper (`pp_container/1`), in the
  spirit of MUI's
  [`Container`](https://mui.com/material-ui/react-container/).

  `max_width` uses Tailwind's own screen-based scale (`sm`/`md`/`lg`/`xl`/
  `"2xl"`/`full`) rather than replicating MUI's specific pixel breakpoints —
  same idea (cap the content width, center it, pad the edges), Tailwind's
  own vocabulary.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:max_width, :string, default: "lg", values: ~w(sm md lg xl 2xl full))
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a centered, max-width container. See the module doc."
  def pp_container(assigns) do
    ~H"""
    <div
      data-pp-component="container"
      class={Helpers.classes(@paperize, paper_classes(@max_width), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(max_width) do
    ["mx-auto w-full px-4", max_width_class(max_width)]
  end

  defp max_width_class("sm"), do: "max-w-screen-sm"
  defp max_width_class("md"), do: "max-w-screen-md"
  defp max_width_class("lg"), do: "max-w-screen-lg"
  defp max_width_class("xl"), do: "max-w-screen-xl"
  defp max_width_class("2xl"), do: "max-w-screen-2xl"
  defp max_width_class("full"), do: "max-w-none"
end
