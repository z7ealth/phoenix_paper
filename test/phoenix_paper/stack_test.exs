defmodule PhoenixPaper.StackTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Stack

  test "defaults to a column flex layout with gap-4" do
    html = render_component(&default/1)

    assert html =~ "flex-col"
    assert html =~ "gap-4"
  end

  defp default(assigns) do
    ~H"""
    <.pp_stack>Content</.pp_stack>
    """
  end

  test "direction=row and a different spacing token change the classes" do
    html = render_component(&row/1)

    assert html =~ "flex-row"
    assert html =~ "gap-1"
    refute html =~ "flex-col"
  end

  defp row(assigns) do
    ~H"""
    <.pp_stack direction="row" spacing={:xs}>Content</.pp_stack>
    """
  end

  test "wrap adds flex-wrap" do
    html = render_component(&wrap/1)
    assert html =~ "flex-wrap"
  end

  defp wrap(assigns) do
    ~H"""
    <.pp_stack wrap>Content</.pp_stack>
    """
  end
end
