defmodule PhoenixPaper.TableContainer do
  @moduledoc """
  The surface around a `PhoenixPaper.Table` (`pp_table_container/1`): an
  MD3 card surface that scrolls horizontally when the table is wider than
  it.

      <.pp_table_container>
        <.pp_table>
          ...
        </.pp_table>
      </.pp_table_container>

  `variant` is `PhoenixPaper.Card`'s: `outlined` (default — `surface` with
  an `outline-variant` border), `elevated` (`surface-container-low` +
  level-1 shadow) or `filled` (`surface-container-highest`), with MD3's
  medium (12dp) corners.

  It's also the scrolling ancestor a `sticky_header` table needs. It
  scrolls horizontally (`overflow-x-auto`); for vertical scrolling add a
  height yourself, e.g. `class="max-h-96 overflow-y-auto"`. A sticky
  header inherits the container's background.

  ## Migrating from 0.4

  `shape` is gone (the corners are MD3's fixed card shape).
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)

  attr(:variant, :string,
    default: "outlined",
    values: ~w(elevated filled outlined),
    doc: "the surface, as for PhoenixPaper.Card"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a table container. See the module doc."
  def pp_table_container(assigns) do
    ~H"""
    <div
      data-pp-component="table-container"
      class={Helpers.classes(@paperize, [surface_classes(@variant), "overflow-x-auto"], @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp surface_classes("elevated"),
    do: "block rounded-pp-md bg-pp-surface-container-low text-pp-on-surface pp-elevation-1"

  defp surface_classes("filled"),
    do: "block rounded-pp-md bg-pp-surface-container-highest text-pp-on-surface"

  defp surface_classes("outlined"),
    do: "block rounded-pp-md border border-pp-outline-variant bg-pp-surface text-pp-on-surface"
end
