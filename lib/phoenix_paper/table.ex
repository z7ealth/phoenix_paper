defmodule PhoenixPaper.Table do
  @moduledoc """
  A data table (`pp_table/1`) built from MD3 parts — renders a `<table>`,
  composed with `PhoenixPaper.TableHead`/`PhoenixPaper.TableBody`/
  `PhoenixPaper.TableRow`/`PhoenixPaper.TableCell` (and optionally
  `PhoenixPaper.TableFooter`, `PhoenixPaper.TableContainer` and
  `PhoenixPaper.TablePagination`):

  [Live demo →](https://phoenixpaper.dev/components/data-display#table)

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

  MD3 doesn't specify a data table, so this is a composite of MD3 parts
  only: `body-medium` cells in `on-surface`, `title-small` headers in
  `on-surface-variant`, `outline-variant` dividers, the 8% state layer on
  row hover, `secondary-container` for selected rows (MD3's selected
  color), and `pp_checkbox`/`pp_icon_button`/`pp_menu` for the
  interactive bits.

  `sticky_header` pins the head to the top of the nearest scrolling
  ancestor (a `TableContainer` with a height limit). It reaches the
  `<thead>` through a descendant selector (`[&_thead]:sticky`) rather than
  an attr threaded through `TableHead`: HEEx can't push an attr into a
  child component the caller wrote, but a CSS descendant selector only
  cares about real DOM nesting.

  ## On compact screens

  A table keeps its columns and scrolls sideways inside a
  `TableContainer`. There's no stacked "rows as cards" mode: MD3 has no
  such pattern, and which columns matter on a phone is the app's call.
  Where a table doesn't fit, render the same rows as a list below MD3's
  medium window size (600dp) and the table above it:

      <.pp_list class="min-[600px]:hidden">
        <.pp_list_item :for={row <- @rows}>
          {row.name}
          <:secondary>{row.amount}</:secondary>
        </.pp_list_item>
      </.pp_list>

      <.pp_table_container class="max-[599px]:hidden">
        ...
      </.pp_table_container>

  ## Migrating from 0.4

  `dense` is gone (it came from MUI's table, not MD3), as is
  `TableBody`'s `striped`.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:paperize, :boolean, default: true)

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
      class={Helpers.classes(@paperize, paper_classes(@sticky_header), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </table>
    """
  end

  defp paper_classes(sticky_header) do
    [
      "w-full border-collapse text-start pp-body-medium text-pp-on-surface",
      sticky_header &&
        "[&_thead]:sticky [&_thead]:top-0 [&_thead]:z-10 [&_thead]:bg-inherit"
    ]
  end
end
