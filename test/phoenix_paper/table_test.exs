defmodule PhoenixPaper.TableTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Table

  test "renders a table with base classes" do
    html = render_component(&table/1)

    assert html =~ "<table"
    assert html =~ "border-collapse"
    assert html =~ "content"
  end

  defp table(assigns) do
    ~H"""
    <.pp_table>content</.pp_table>
    """
  end

  test "dense reduces descendant cell padding via a compound selector" do
    html = render_component(&dense/1)
    assert html =~ "py-1.5"
  end

  defp dense(assigns) do
    ~H"""
    <.pp_table dense>content</.pp_table>
    """
  end

  test "sticky_header pins descendant thead to the top" do
    html = render_component(&sticky/1)
    assert html =~ "thead]:sticky"
    assert html =~ "thead]:top-0"
  end

  defp sticky(assigns) do
    ~H"""
    <.pp_table sticky_header>content</.pp_table>
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "border-collapse"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_table paperize={false} class="my-class">content</.pp_table>
    """
  end
end
