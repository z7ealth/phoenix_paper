defmodule PhoenixPaper.ButtonGroup do
  @moduledoc """
  A Material Design button group (`pp_button_group/1`) — visually joins a
  row of `PhoenixPaper.Button`s (or `PhoenixPaper.ToggleButton`s) into one
  segmented control by rounding only the group's outer corners and
  collapsing the shared borders.

  Give each inner button `variant="outlined"` for the classic segmented
  look — the group overrides each child's own corner rounding regardless of
  its `shape` attr, so you don't need to set `shape={:none}` yourself.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)

  attr(:shape, :atom,
    default: :md,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(role))

  slot(:inner_block, required: true)

  @doc "Renders a button group. See the module doc."
  def pp_button_group(assigns) do
    ~H"""
    <div
      data-pp-component="button-group"
      role="group"
      class={Helpers.classes(@paperize, paper_classes(@shape), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(shape) do
    [
      "inline-flex [&>*]:rounded-none [&>*:not(:first-child)]:-ml-px [&>*:focus-visible]:z-10 [&>*:hover]:z-10",
      corner_classes(shape)
    ]
  end

  defp corner_classes(:none), do: "[&>*:first-child]:rounded-none [&>*:last-child]:rounded-none"
  defp corner_classes(:xs), do: "[&>*:first-child]:rounded-l-sm [&>*:last-child]:rounded-r-sm"
  defp corner_classes(:sm), do: "[&>*:first-child]:rounded-l [&>*:last-child]:rounded-r"
  defp corner_classes(:md), do: "[&>*:first-child]:rounded-l-md [&>*:last-child]:rounded-r-md"
  defp corner_classes(:lg), do: "[&>*:first-child]:rounded-l-lg [&>*:last-child]:rounded-r-lg"
  defp corner_classes(:xl), do: "[&>*:first-child]:rounded-l-xl [&>*:last-child]:rounded-r-xl"

  defp corner_classes(:full),
    do: "[&>*:first-child]:rounded-l-full [&>*:last-child]:rounded-r-full"
end
