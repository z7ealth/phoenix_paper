defmodule PhoenixPaper.GridItemTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.GridItem

  test "span sets the base col-span and defaults to full width" do
    html = render_component(&default/1)
    assert html =~ "col-span-12"
  end

  defp default(assigns) do
    ~H"""
    <.pp_grid_item>Content</.pp_grid_item>
    """
  end

  test "md overrides the span at the md: breakpoint" do
    html = render_component(&responsive/1)

    assert html =~ "col-span-12"
    assert html =~ "md:col-span-4"
  end

  defp responsive(assigns) do
    ~H"""
    <.pp_grid_item span={12} md={4}>Content</.pp_grid_item>
    """
  end

  test "no md override means no md: class at all" do
    html = render_component(&no_md/1)
    refute html =~ "md:col-span"
  end

  defp no_md(assigns) do
    ~H"""
    <.pp_grid_item span={6}>Content</.pp_grid_item>
    """
  end
end
