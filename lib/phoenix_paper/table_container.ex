defmodule PhoenixPaper.TableContainer do
  @moduledoc """
  A horizontally-scrolling wrapper for `PhoenixPaper.Table` (`pp_table_container/1`)
  — composes `PhoenixPaper.Paper` for the surface (background, elevation,
  rounded corners), the same pairing MUI's own docs show
  (`<TableContainer component={Paper}>`).

      <.pp_table_container>
        <.pp_table>
          ...
        </.pp_table>
      </.pp_table_container>

  Also the ancestor a `sticky_header` table needs: `position: sticky` pins an
  element to the top of its nearest *scrolling* ancestor, and this is that
  ancestor (`overflow-x-auto` — vertical scrolling, if the table is tall
  enough to need it, has to come from a `class` you add yourself, e.g.
  `class="max-h-96 overflow-y-auto"`, since a table wide enough to need
  horizontal scroll but not tall enough to need vertical scroll is the more
  common case, and forcing both isn't always wanted).

  `variant` picks the surface the way `PhoenixPaper.Card`'s does:
  `outlined` (default — an `outline-variant` border), `elevated`
  (`surface-container-low` + level-1 shadow) or `filled`
  (`surface-container-highest`). 0.3's `elevation` attr is gone. A sticky
  header inherits the container's background.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  import PhoenixPaper.Paper, only: [pp_paper: 1]

  attr(:paperize, :boolean, default: true)

  attr(:variant, :string,
    default: "outlined",
    values: ~w(elevated filled outlined),
    doc: "the surface, as for PhoenixPaper.Card"
  )

  attr(:shape, :atom,
    default: :md,
    values: PhoenixPaper.Shape.tokens(),
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a table container. See the module doc."
  def pp_table_container(assigns) do
    ~H"""
    <.pp_paper
      color={surface(@variant)}
      elevation={if @variant == "elevated", do: 1, else: 0}
      outlined={@variant == "outlined"}
      shape={@shape}
      paperize={@paperize}
      component="table-container"
      class={Helpers.classes(@paperize, "overflow-x-auto", @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.pp_paper>
    """
  end

  defp surface("elevated"), do: "surface-container-low"
  defp surface("filled"), do: "surface-container-highest"
  defp surface("outlined"), do: "surface"
end
