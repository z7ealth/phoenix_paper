defmodule PhoenixPaper.TableCell do
  @moduledoc """
  A cell inside a `PhoenixPaper.TableRow` (`pp_table_cell/1`) — renders a
  `<th>` when `variant="head"`, a `<td>` otherwise. See
  `PhoenixPaper.Table`'s moduledoc for a full example.

  Head cells are `title-small` in `on-surface-variant`, body cells inherit
  the table's `body-medium`; both have 16dp side padding.

  `sortable` turns a head cell into a button with a direction arrow (an
  MD3 icon, `hero-arrow-up`, rotated for descending), styled by
  `sort_direction` (`nil` — sortable but not the active column, `"asc"`,
  or `"desc"`, which also set `aria-sort` on the `<th>`). It's
  presentation only: wire your own `phx-click`/`phx-value-*` through the
  global attrs (e.g. `phx-click="sort" phx-value-column="name"`); the
  LiveView owns which column is active and in which direction, as it owns
  the sorted data. `rest` lands on the `<button>` when `sortable`, or on
  the `<th>`/`<td>` itself otherwise (e.g. for `colspan`/`rowspan`).
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.Icon, only: [pp_icon: 1]

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
    <th
      :if={@variant == "head" && @sortable}
      aria-sort={aria_sort(@sort_direction)}
      class={Helpers.classes(@paperize, head_classes(@align), @class)}
    >
      <button type="button" class={Helpers.classes(@paperize, sort_button_classes(), nil)} {@rest}>
        {render_slot(@inner_block)}
        <.pp_icon
          name="hero-arrow-up"
          size="xs"
          class={Helpers.classes(@paperize, sort_arrow_classes(@sort_direction), nil)}
        />
      </button>
    </th>
    <td :if={@variant == "body"} class={Helpers.classes(@paperize, body_classes(@align), @class)} {@rest}>
      {render_slot(@inner_block)}
    </td>
    """
  end

  defp head_classes(align) do
    [
      "px-4 py-3 pp-title-small whitespace-nowrap text-pp-on-surface-variant",
      align_classes(align)
    ]
  end

  defp body_classes(align) do
    ["px-4 py-3", align_classes(align)]
  end

  defp align_classes("left"), do: "text-start"
  defp align_classes("center"), do: "text-center"
  defp align_classes("right"), do: "text-end"

  defp sort_button_classes do
    "inline-flex cursor-pointer select-none items-center gap-1 rounded-pp-xs hover:text-pp-on-surface pp-focus-ring"
  end

  defp sort_arrow_classes(nil), do: "opacity-38 pp-motion-spatial-fast"
  defp sort_arrow_classes("asc"), do: "opacity-100 pp-motion-spatial-fast"
  defp sort_arrow_classes("desc"), do: "rotate-180 opacity-100 pp-motion-spatial-fast"

  defp aria_sort("asc"), do: "ascending"
  defp aria_sort("desc"), do: "descending"
  defp aria_sort(_), do: "none"
end
