defmodule PhoenixPaper.TableBody do
  @moduledoc """
  The body section of a `PhoenixPaper.Table` (`pp_table_body/1`) — renders a
  `<tbody>` of `PhoenixPaper.TableRow`s. See `PhoenixPaper.Table`'s moduledoc
  for a full example.

  Row dividers live here too, the same way `dense`/`sticky_header` live on
  `PhoenixPaper.Table`: a CSS descendant selector scoped to `> tr` (this
  body's own direct child rows only, not a header/footer row elsewhere in
  the table), with the last row's divider removed so the body doesn't end on
  a stray line right above the footer/table edge.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)

  attr(:striped, :boolean,
    default: false,
    doc: "alternating row background on every other row"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a table body. See the module doc."
  def pp_table_body(assigns) do
    ~H"""
    <tbody
      data-pp-component="table-body"
      class={Helpers.classes(@paperize, paper_classes(@striped), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </tbody>
    """
  end

  defp paper_classes(striped) do
    [
      "[&>tr]:border-b [&>tr]:border-pp-outline/15 [&>tr:last-child]:border-b-0",
      striped_classes(striped)
    ]
  end

  defp striped_classes(false), do: ""
  defp striped_classes(true), do: "[&>tr:nth-child(even)]:bg-pp-surface-variant/30"
end
