defmodule PhoenixPaper.TableHead do
  @moduledoc """
  The header section of a `PhoenixPaper.Table` (`pp_table_head/1`) — renders
  a `<thead>` containing `PhoenixPaper.TableRow`s of `variant="head"`
  `PhoenixPaper.TableCell`s. See `PhoenixPaper.Table`'s moduledoc for a full
  example.

  The border under the header lives here (on every descendant `<th>`, not on
  the `<thead>` element itself — a `border-bottom` on `<thead>` doesn't
  render reliably across browsers once `border-collapse` is set on the table,
  but one on each `<th>` does).
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a table head. See the module doc."
  def pp_table_head(assigns) do
    ~H"""
    <thead
      data-pp-component="table-head"
      class={Helpers.classes(@paperize, "[&_th]:border-b-2 [&_th]:border-pp-outline", @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </thead>
    """
  end
end
