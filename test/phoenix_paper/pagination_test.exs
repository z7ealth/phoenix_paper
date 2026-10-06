defmodule PhoenixPaper.PaginationTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Pagination

  doctest PhoenixPaper.Pagination

  describe "items/2" do
    test "keeps the same length while paging through many pages" do
      lengths = for page <- 1..20, do: length(items(page, 20))
      assert Enum.uniq(lengths) == [7]
    end

    test "fills a single-page gap with the page instead of an ellipsis" do
      assert items(4, 20) == [1, 2, 3, 4, 5, :end_ellipsis, 20]
      assert items(17, 20) == [1, :start_ellipsis, 16, 17, 18, 19, 20]
    end

    test "no pages at all" do
      assert items(1, 0) == []
    end
  end

  defp linked(assigns) do
    ~H"""
    <.pp_pagination page={6} count={20} path={&"/users?page=#{&1}"} />
    """
  end

  test "path makes each page a patch link, marking the current one" do
    html = render_component(&linked/1)

    assert html =~ ~s(data-pp-component="pagination")
    assert html =~ ~s(href="/users?page=5")
    assert html =~ ~s(data-phx-link="patch")
    assert html =~ ~s(aria-current="page")
    assert html =~ ~s(aria-label="Go to previous page")
    assert html =~ ~s(href="/users?page=7")
    assert html =~ "…"
    assert html =~ "bg-pp-secondary-container text-pp-on-secondary-container"
    assert html =~ "h-10 min-w-10"
    assert html =~ "pp-state-layer"
    assert html =~ "cursor-pointer"
  end

  defp navigate(assigns) do
    ~H"""
    <.pp_pagination page={1} count={3} path={&"/p/#{&1}"} link="navigate" />
    """
  end

  test "link=navigate and a disabled previous button on the first page" do
    html = render_component(&navigate/1)

    assert html =~ ~s(data-phx-link="redirect")
    assert html =~ ~r/<button[^>]*disabled[^>]*aria-label="Go to previous page"/
    refute html =~ ~s(href="/p/0")
  end

  defp evented(assigns) do
    ~H"""
    <.pp_pagination
      page={2}
      count={3}
      on_change="paginate"
      target="#list"
    />
    """
  end

  test "on_change renders buttons sending phx-value-page" do
    html = render_component(&evented/1)

    assert html =~ ~s(phx-click="paginate")
    assert html =~ ~s(phx-value-page="3")
    assert html =~ ~s(phx-target="#list")
    assert html =~ ~s(aria-label="Go to next page")
    refute html =~ "first page"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_pagination page={1} count={2} on_change="p" paperize={false} class="my-pages" />
    """
  end

  test "paperize={false} drops built-in item classes, keeps the caller class" do
    html = render_component(&bare/1)

    assert html =~ "my-pages"
    refute html =~ "cursor-pointer"
    refute html =~ "bg-pp-secondary-container"
    assert html =~ ~s(phx-value-page="2")
  end
end
