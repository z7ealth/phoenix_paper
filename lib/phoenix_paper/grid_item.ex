defmodule PhoenixPaper.GridItem do
  @moduledoc """
  A column-spanning child (`pp_grid_item/1`) of `PhoenixPaper.Grid`, in the
  spirit of MUI's [`Grid`](https://mui.com/material-ui/react-grid/) `item`.

  `span` sets the column span (1-12) at all sizes; `md` optionally overrides
  it at the `md:` breakpoint and up (e.g. full-width on mobile, a third of
  the grid on desktop: `span={12} md={4}`). Only the `md:` breakpoint is
  supported for now — not the full `sm`/`lg`/`xl` breakpoint set MUI offers
  — since every value has to be a literal Tailwind class (see AGENTS.md,
  "Tailwind class safety"), and `md:` alone covers the common
  "stack-on-mobile, columns-on-desktop" case. Ask if you need more
  breakpoints; the pattern (`col_span_lg/1` etc.) is mechanical to extend.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:span, :integer, default: 12, values: Enum.to_list(1..12))
  attr(:md, :integer, default: nil, values: [nil | Enum.to_list(1..12)])
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a grid item. See the module doc."
  def pp_grid_item(assigns) do
    ~H"""
    <div
      data-pp-component="grid-item"
      class={Helpers.classes(@paperize, paper_classes(@span, @md), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(span, md), do: [col_span(span), col_span_md(md)]

  defp col_span(1), do: "col-span-1"
  defp col_span(2), do: "col-span-2"
  defp col_span(3), do: "col-span-3"
  defp col_span(4), do: "col-span-4"
  defp col_span(5), do: "col-span-5"
  defp col_span(6), do: "col-span-6"
  defp col_span(7), do: "col-span-7"
  defp col_span(8), do: "col-span-8"
  defp col_span(9), do: "col-span-9"
  defp col_span(10), do: "col-span-10"
  defp col_span(11), do: "col-span-11"
  defp col_span(12), do: "col-span-12"

  defp col_span_md(nil), do: ""
  defp col_span_md(1), do: "md:col-span-1"
  defp col_span_md(2), do: "md:col-span-2"
  defp col_span_md(3), do: "md:col-span-3"
  defp col_span_md(4), do: "md:col-span-4"
  defp col_span_md(5), do: "md:col-span-5"
  defp col_span_md(6), do: "md:col-span-6"
  defp col_span_md(7), do: "md:col-span-7"
  defp col_span_md(8), do: "md:col-span-8"
  defp col_span_md(9), do: "md:col-span-9"
  defp col_span_md(10), do: "md:col-span-10"
  defp col_span_md(11), do: "md:col-span-11"
  defp col_span_md(12), do: "md:col-span-12"
end
