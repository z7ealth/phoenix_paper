defmodule PhoenixPaper.TableCellTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.TableCell

  test "variant=\"body\" (default) renders a td" do
    html = render_component(&body_cell/1)

    assert html =~ "<td"
    refute html =~ "<th"
    assert html =~ "Coffee"
  end

  defp body_cell(assigns) do
    ~H"""
    <.pp_table_cell>Coffee</.pp_table_cell>
    """
  end

  test "variant=\"head\" renders a th" do
    html = render_component(&head_cell/1)

    assert html =~ "<th"
    refute html =~ "<td"
    assert html =~ "Name"
  end

  defp head_cell(assigns) do
    ~H"""
    <.pp_table_cell variant="head">Name</.pp_table_cell>
    """
  end

  test "align=\"right\" applies text-right" do
    html = render_component(&right_aligned/1)
    assert html =~ "text-right"
  end

  defp right_aligned(assigns) do
    ~H"""
    <.pp_table_cell align="right">$4.50</.pp_table_cell>
    """
  end

  test "sortable renders a clickable button with an arrow, forwarding rest to the button" do
    html = render_component(&sortable/1)

    assert html =~ "<button"
    assert html =~ ~s(phx-click="sort")
    assert html =~ "▲"
  end

  defp sortable(assigns) do
    ~H"""
    <.pp_table_cell variant="head" sortable phx-click="sort">Name</.pp_table_cell>
    """
  end

  test "sort_direction=\"desc\" rotates the arrow" do
    html = render_component(&sorted_desc/1)
    assert html =~ "rotate-180"
  end

  defp sorted_desc(assigns) do
    ~H"""
    <.pp_table_cell variant="head" sortable sort_direction="desc">Name</.pp_table_cell>
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "text-sm"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_table_cell paperize={false} class="my-class">Coffee</.pp_table_cell>
    """
  end
end
