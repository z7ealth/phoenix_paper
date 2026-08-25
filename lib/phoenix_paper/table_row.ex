defmodule PhoenixPaper.TableRow do
  @moduledoc """
  A row inside `PhoenixPaper.TableHead`/`PhoenixPaper.TableBody`/
  `PhoenixPaper.TableFooter` (`pp_table_row/1`) — renders a `<tr>` with a
  hover highlight. See `PhoenixPaper.Table`'s moduledoc for a full example.

  `selected` renders a stronger, persistent highlight (e.g. for a checkbox-
  selected row) — pair it with a `PhoenixPaper.Checkbox` in the first
  `PhoenixPaper.TableCell` and your own `phx-click`/assign to track which
  rows are selected; that state isn't something this stateless component can
  own itself.

  `selected`'s background uses `!bg-pp-primary/10` (the `!` = Tailwind's
  important modifier), not a plain `bg-pp-primary/10` — `PhoenixPaper.TableBody`'s
  `striped` option sets its alternating background via a compound descendant
  selector (`[&>tr:nth-child(even)]:...`), which has higher CSS specificity
  than a bare class on the row itself, so a plain class here would silently
  lose to the stripe on every other row. `!important` wins regardless of
  specificity, so `selected` reliably wins over `striped` either way.
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
      class={Helpers.classes(@paperize, paper_classes(@selected), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </tr>
    """
  end

  defp paper_classes(false), do: "transition-colors hover:bg-pp-on-surface/5"
  defp paper_classes(true), do: "!bg-pp-primary/10 transition-colors hover:!bg-pp-primary/15"
end
