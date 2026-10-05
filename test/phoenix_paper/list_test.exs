defmodule PhoenixPaper.ListTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.List

  test "renders a role=list container wrapping its children" do
    html = render_component(&list/1)

    assert html =~ ~s(role="list")
    assert html =~ "Item"
  end

  defp list(assigns) do
    ~H"""
    <.pp_list>Item</.pp_list>
    """
  end

  test "paperize={false} drops built-in classes" do
    html = render_component(&bare/1)
    refute html =~ "flex-col"
    assert html =~ "my-list"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_list paperize={false} class="my-list">Item</.pp_list>
    """
  end
end
