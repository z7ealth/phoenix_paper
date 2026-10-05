defmodule PhoenixPaper.TablePaginationTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.TablePagination

  defp linked(assigns) do
    ~H"""
    <.pp_table_pagination
      id="users-pagination"
      page={2}
      count={47}
      rows_per_page={10}
      path={&"/users?page=#{&1}&per_page=#{&2}"}
    />
    """
  end

  test "shows the displayed range and links prev/next keeping rows_per_page" do
    html = render_component(&linked/1)

    assert html =~ ~s(data-pp-component="table-pagination")
    assert html =~ "11–20 of 47"
    assert html =~ ~s(href="/users?page=1&amp;per_page=10")
    assert html =~ ~s(href="/users?page=3&amp;per_page=10")
    assert html =~ ~s(data-phx-link="patch")
    assert html =~ "Rows per page:"
  end

  test "picking a page size links to page 1 with that size, marking the current one" do
    html = render_component(&linked/1)

    assert html =~ ~s(href="/users?page=1&amp;per_page=25")
    assert html =~ ~s(href="/users?page=1&amp;per_page=100")
    assert html =~ ~s(id="users-pagination-rows-per-page-trigger")
    assert html =~ ~s(aria-current="page")
  end

  defp last_page(assigns) do
    ~H"""
    <.pp_table_pagination
      id="p"
      page={5}
      count={47}
      rows_per_page={10}
      path={&"/u?page=#{&1}&per_page=#{&2}"}
      show_first_button
      show_last_button
    />
    """
  end

  test "next/last are disabled buttons on the last page" do
    html = render_component(&last_page/1)

    assert html =~ "41–47 of 47"
    assert html =~ ~r/<button[^>]*disabled[^>]*aria-label="Go to next page"/
    assert html =~ ~r/<button[^>]*disabled[^>]*aria-label="Go to last page"/
    refute html =~ ~s(href="/u?page=6)
    assert html =~ ~s(aria-label="Go to first page")
  end

  defp evented(assigns) do
    ~H"""
    <.pp_table_pagination
      id="p"
      page={1}
      count={0}
      rows_per_page={25}
      rows_per_page_options={[5, 25]}
      on_page_change="page"
      on_rows_per_page_change="per_page"
      target="#t"
      label_rows_per_page="Filas:"
      label_displayed_rows={fn %{from: f, to: t, count: c} -> "#{f}-#{t} de #{c}" end}
    />
    """
  end

  test "event mode, empty table and custom labels" do
    html = render_component(&evented/1)

    assert html =~ "0-0 de 0"
    assert html =~ "Filas:"
    assert html =~ ~s(phx-click="per_page")
    assert html =~ ~s(phx-value-rows_per_page="5")
    assert html =~ ~s(phx-target="#t")
    assert html =~ ~r/<button[^>]*disabled[^>]*aria-label="Go to next page"/
  end

  defp no_picker(assigns) do
    ~H"""
    <.pp_table_pagination
      id="p"
      page={1}
      count={30}
      rows_per_page={10}
      rows_per_page_options={[]}
      on_page_change="page"
      paperize={false}
      class="my-bar"
    />
    """
  end

  test "rows_per_page_options=[] hides the picker; paperize={false} drops the bar's skin" do
    html = render_component(&no_picker/1)

    refute html =~ "Rows per page:"
    assert html =~ ~s(phx-value-page="2")
    assert html =~ "my-bar"
    refute html =~ "justify-end gap-x-6"
  end

  test "the id lands on the root, like pp_pagination's" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhoenixPaper.TablePagination.pp_table_pagination
        id="users-pagination"
        page={1}
        count={47}
        rows_per_page={10}
        on_page_change="page"
      />
      """)

    assert html =~ ~r/<div[^>]*id="users-pagination"[^>]*data-pp-component="table-pagination"/
    assert html =~ ~s(id="users-pagination-rows-per-page-trigger")
  end
end
