defmodule PhoenixPaper.TableCell do
  @moduledoc """
  A cell inside a `PhoenixPaper.TableRow` (`pp_table_cell/1`) — renders a
  `<th>` when `variant="head"`, a `<td>` otherwise. See
  `PhoenixPaper.Table`'s moduledoc for a full example.

  `sortable` turns a head cell into MUI's `TableSortLabel` equivalent: a
  clickable button with a direction arrow, styled by `sort_direction`
  (`nil` — sortable but not the active column, `"asc"`, or `"desc"`). Unlike
  MUI, this is presentation only — there's no click handling built in, wire
  your own `phx-click`/`phx-value-*` via the normal global attrs (e.g.
  `phx-click="sort" phx-value-column="name"`); the LiveView owns which
  column is active and in which direction, the same as it owns the actual
  sorted data. `rest` lands on the `<button>` when `sortable`, or on the
  `<th>`/`<td>` itself otherwise (e.g. for `colspan`/`rowspan`).
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)
  attr(:variant, :string, default: "body", values: ~w(head body))
  attr(:align, :string, default: "left", values: ~w(left center right))

  attr(:sortable, :boolean,
    default: false,
    doc: "renders a clickable sort-direction arrow — only meaningful with variant=\"head\""
  )

  attr(:sort_direction, :string,
    default: nil,
    doc: "nil (sortable but inactive) | \"asc\" | \"desc\" — only meaningful with sortable"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(colspan rowspan))

  slot(:inner_block, required: true)

  @doc "Renders a table cell. See the module doc."
  def pp_table_cell(assigns) do
    ~H"""
    <th
      :if={@variant == "head" && !@sortable}
      class={Helpers.classes(@paperize, head_classes(@align), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </th>
    <th :if={@variant == "head" && @sortable} class={Helpers.classes(@paperize, head_classes(@align), @class)}>
      <button type="button" class={Helpers.classes(@paperize, sort_button_classes(), nil)} {@rest}>
        {render_slot(@inner_block)}
        <span class={Helpers.classes(@paperize, sort_arrow_classes(@sort_direction), nil)}>▲</span>
      </button>
    </th>
    <td :if={@variant == "body"} class={Helpers.classes(@paperize, body_classes(@align), @class)} {@rest}>
      {render_slot(@inner_block)}
    </td>
    """
  end

  defp head_classes(align) do
    [
      "px-4 py-3 text-xs font-medium uppercase tracking-wide whitespace-nowrap text-pp-on-surface/70",
      align_classes(align)
    ]
  end

  defp body_classes(align) do
    ["px-4 py-3 text-sm text-pp-on-surface", align_classes(align)]
  end

  defp align_classes("left"), do: "text-left"
  defp align_classes("center"), do: "text-center"
  defp align_classes("right"), do: "text-right"

  defp sort_button_classes do
    "inline-flex cursor-pointer select-none items-center gap-1 uppercase tracking-wide hover:text-pp-primary"
  end

  defp sort_arrow_classes(nil), do: "inline-block text-xs opacity-30 transition-transform"
  defp sort_arrow_classes("asc"), do: "inline-block text-xs opacity-100 transition-transform"

  defp sort_arrow_classes("desc"),
    do: "inline-block rotate-180 text-xs opacity-100 transition-transform"
end
