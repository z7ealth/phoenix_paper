defmodule PhoenixPaper.TableRow do
  @moduledoc """
  A row inside `PhoenixPaper.TableHead`/`PhoenixPaper.TableBody`/
  `PhoenixPaper.TableFooter` (`pp_table_row/1`) — renders a `<tr>` with
  MD3's 8% `on-surface` state layer on hover. See `PhoenixPaper.Table`'s
  moduledoc for a full example.

  `selected` gives the row MD3's selected color (`secondary-container`)
  and sets `aria-selected`. Pair it with a `PhoenixPaper.Checkbox` in the
  first cell and your own `phx-click`/assign to track which rows are
  selected; that state isn't something this stateless component can own.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)
  attr(:selected, :boolean, default: false, doc: "a stronger, persistent highlight")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a table row. See the module doc."
  def pp_table_row(assigns) do
    ~H"""
    <tr
      data-pp-component="table-row"
      aria-selected={@selected && "true"}
      class={Helpers.classes(@paperize, paper_classes(@selected), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </tr>
    """
  end

  defp paper_classes(false), do: "pp-motion-effects-fast hover:bg-pp-on-surface/8"

  defp paper_classes(true),
    do: "bg-pp-secondary-container text-pp-on-secondary-container pp-motion-effects-fast"
end
