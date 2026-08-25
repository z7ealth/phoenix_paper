defmodule PhoenixPaper.ButtonGroup do
  @moduledoc """
  A Material Design button group (`pp_button_group/1`) — visually joins a
  row of `PhoenixPaper.Button`s (or `PhoenixPaper.ToggleButton`s) into one
  segmented control by rounding only the group's outer corners and
  collapsing the shared borders.

  Give each inner button `variant="outlined"` for the classic segmented
  look — the group overrides each child's own corner rounding regardless of
  its `shape` attr, so you don't need to set `shape={:none}` yourself.

  `orientation="vertical"` stacks buttons top-to-bottom instead of side by
  side, collapsing the shared borders the same way (top/bottom instead of
  left/right).

  `disable_elevation` zeroes out every child button's own elevation shadow
  (the same idea as MUI's `disableElevation`) — set it once on the group
  instead of `elevation={0}` on every button.

  Unlike MUI, there's no group-level `variant`/`color`/`size` that cascades
  to children — MUI does that through React context, which HEEx has no
  equivalent for. `render_slot/1` just re-renders whatever HEEx markup the
  caller wrote for `inner_block`; there's no hook for a parent component to
  reach into a child's own assigns and change them. Set those attrs on each
  `<.pp_button>` yourself.

  There's also no built-in "split button" (a button plus a small
  dropdown-toggle button opening a menu) — that needs a menu/popover
  component this library doesn't have yet, not just a `ButtonGroup` option.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)

  attr(:orientation, :string,
    default: "horizontal",
    values: ~w(horizontal vertical),
    doc: "stack buttons side by side or top-to-bottom"
  )

  attr(:shape, :atom,
    default: :md,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:disable_elevation, :boolean,
    default: false,
    doc: "zero out every child button's own elevation shadow"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(role))

  slot(:inner_block, required: true)

  @doc "Renders a button group. See the module doc."
  def pp_button_group(assigns) do
    ~H"""
    <div
      data-pp-component="button-group"
      data-pp-orientation={@orientation}
      role="group"
      class={
        Helpers.classes(
          @paperize,
          paper_classes(@orientation, @shape, @disable_elevation),
          @class
        )
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(orientation, shape, disable_elevation) do
    [
      layout_classes(orientation),
      corner_classes(orientation, shape),
      elevation_classes(disable_elevation)
    ]
  end

  defp layout_classes("horizontal") do
    "inline-flex [&>*]:rounded-none [&>*:not(:first-child)]:-ml-px [&>*:focus-visible]:z-10 [&>*:hover]:z-10"
  end

  defp layout_classes("vertical") do
    "inline-flex flex-col [&>*]:rounded-none [&>*:not(:first-child)]:-mt-px [&>*:focus-visible]:z-10 [&>*:hover]:z-10"
  end

  defp corner_classes("horizontal", :none),
    do: "[&>*:first-child]:rounded-none [&>*:last-child]:rounded-none"

  defp corner_classes("horizontal", :xs),
    do: "[&>*:first-child]:rounded-l-sm [&>*:last-child]:rounded-r-sm"

  defp corner_classes("horizontal", :sm),
    do: "[&>*:first-child]:rounded-l [&>*:last-child]:rounded-r"

  defp corner_classes("horizontal", :md),
    do: "[&>*:first-child]:rounded-l-md [&>*:last-child]:rounded-r-md"

  defp corner_classes("horizontal", :lg),
    do: "[&>*:first-child]:rounded-l-lg [&>*:last-child]:rounded-r-lg"

  defp corner_classes("horizontal", :xl),
    do: "[&>*:first-child]:rounded-l-xl [&>*:last-child]:rounded-r-xl"

  defp corner_classes("horizontal", :full),
    do: "[&>*:first-child]:rounded-l-full [&>*:last-child]:rounded-r-full"

  defp corner_classes("vertical", :none),
    do: "[&>*:first-child]:rounded-none [&>*:last-child]:rounded-none"

  defp corner_classes("vertical", :xs),
    do: "[&>*:first-child]:rounded-t-sm [&>*:last-child]:rounded-b-sm"

  defp corner_classes("vertical", :sm),
    do: "[&>*:first-child]:rounded-t [&>*:last-child]:rounded-b"

  defp corner_classes("vertical", :md),
    do: "[&>*:first-child]:rounded-t-md [&>*:last-child]:rounded-b-md"

  defp corner_classes("vertical", :lg),
    do: "[&>*:first-child]:rounded-t-lg [&>*:last-child]:rounded-b-lg"

  defp corner_classes("vertical", :xl),
    do: "[&>*:first-child]:rounded-t-xl [&>*:last-child]:rounded-b-xl"

  defp corner_classes("vertical", :full),
    do: "[&>*:first-child]:rounded-t-full [&>*:last-child]:rounded-b-full"

  defp elevation_classes(false), do: ""
  defp elevation_classes(true), do: "[&>*]:pp-elevation-0"
end
