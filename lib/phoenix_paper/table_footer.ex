defmodule PhoenixPaper.TableFooter do
  @moduledoc """
  An optional footer section of a `PhoenixPaper.Table` (`pp_table_footer/1`)
  — renders a `<tfoot>` of `PhoenixPaper.TableRow`s, typically for totals or
  summary values. See `PhoenixPaper.Table`'s moduledoc for a full example.

  Like `PhoenixPaper.TableHead`, the separating border lives on every
  descendant cell rather than on the `<tfoot>` element itself, for the same
  cross-browser reason.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a table footer. See the module doc."
  def pp_table_footer(assigns) do
    ~H"""
    <tfoot
      data-pp-component="table-footer"
      class={
        Helpers.classes(
          @paperize,
          "[&_td]:border-t-2 [&_td]:border-pp-outline [&_td]:font-medium",
          @class
        )
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </tfoot>
    """
  end
end
