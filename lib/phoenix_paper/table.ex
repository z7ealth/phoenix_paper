defmodule PhoenixPaper.Table do
  @moduledoc """
  A Material Design table (`pp_table/1`) — renders a `<table>`, composed
  with `PhoenixPaper.TableHead`/`PhoenixPaper.TableBody`/
  `PhoenixPaper.TableRow`/`PhoenixPaper.TableCell` (and optionally
  `PhoenixPaper.TableFooter`, `PhoenixPaper.TableContainer`):

      <.pp_table_container>
        <.pp_table>
          <.pp_table_head>
            <.pp_table_row>
              <.pp_table_cell variant="head">Name</.pp_table_cell>
              <.pp_table_cell variant="head" align="right">Amount</.pp_table_cell>
            </.pp_table_row>
          </.pp_table_head>
          <.pp_table_body>
            <.pp_table_row>
              <.pp_table_cell>Coffee</.pp_table_cell>
              <.pp_table_cell align="right">$4.50</.pp_table_cell>
            </.pp_table_row>
          </.pp_table_body>
        </.pp_table>
      </.pp_table_container>

  `dense` and `sticky_header` are set once here and reach every cell/head via
  plain CSS descendant selectors (`[&_td]:...`), not by threading an attr
  through every `TableCell` — unlike MUI, HEEx has no context mechanism to
  cascade a prop from `Table` down to children `TableCell`s a caller wrote
  themselves (see `PhoenixPaper.ButtonGroup`'s moduledoc for the same
  limitation), but a CSS descendant selector doesn't care about component
  boundaries, only real DOM nesting — so it works here where it couldn't for
  ButtonGroup's `color`/`variant` (there's no single class that could express
  "make this children's `color` prop `secondary`").

  `TableCell` still carries its own sensible default padding, so cells look
  right when rendered outside a `Table` too (e.g. in isolation in tests) —
  `Table`'s descendant selectors just override it via the extra specificity a
  compound selector gets over a bare utility class.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)

  attr(:dense, :boolean,
    default: false,
    doc: "tighter vertical cell padding, applied to every descendant th/td"
  )

  attr(:sticky_header, :boolean,
    default: false,
    doc: "pins TableHead to the top of the nearest scrolling ancestor, e.g. TableContainer"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a table. See the module doc."
  def pp_table(assigns) do
    ~H"""
    <table
      data-pp-component="table"
      class={Helpers.classes(@paperize, paper_classes(@dense, @sticky_header), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </table>
    """
  end

  defp paper_classes(dense, sticky_header) do
    [
      "w-full border-collapse text-left text-sm text-pp-on-surface",
      cell_padding_classes(dense),
      sticky_header_classes(sticky_header)
    ]
  end

  defp cell_padding_classes(false), do: "[&_th]:py-3 [&_td]:py-3"
  defp cell_padding_classes(true), do: "[&_th]:py-1.5 [&_td]:py-1.5"

  defp sticky_header_classes(false), do: ""

  defp sticky_header_classes(true),
    do: "[&_thead]:sticky [&_thead]:top-0 [&_thead]:z-10 [&_thead]:bg-pp-surface"
end
