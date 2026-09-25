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

  test "dense, nested and inset reach the items" do
    assigns = %{}

    html =
      rendered_to_string(~H"<.pp_list dense nested inset><span>x</span></.pp_list>")

    assert html =~ "[&amp;_[data-pp-component=list-item]]:py-1"
    assert html =~ "pl-4"
    assert html =~ ":not(:has([data-pp-list-item-leading]))]:pl-13"
  end

  describe "pp_list_group" do
    defp group(assigns) do
      ~H"""
      <.pp_list>
        <.pp_list_group id="forms" default_open>
          <:leading><span>i</span></:leading>
          <:label>Forms</:label>
          <span>Input</span>
        </.pp_list_group>
      </.pp_list>
      """
    end

    test "wires a checkbox, a list-item-shaped label trigger and a nested list" do
      html = render_component(&group/1)

      assert html =~ ~s(id="forms-toggle")
      assert html =~ "checked"
      assert html =~ ~s(for="forms-toggle")
      assert html =~ ~s(data-pp-component="list-group")
      assert html =~ ~s(<label for="forms-toggle" data-pp-component="list-item")
      assert html =~ ~s(id="forms-content")
      assert html =~ "peer-checked:grid-rows-[1fr]"
      assert html =~ "Forms"
      assert html =~ "Input"
    end

    test "paperize={false} keeps the show/hide wiring but drops the skin" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_list_group id="g" paperize={false} class="mine">
          <:label>G</:label>
          x
        </.pp_list_group>
        """)

      assert html =~ "peer-checked:grid-rows-[1fr]"
      assert html =~ "mine"
      refute html =~ "hover:bg-pp-on-surface/10"
      refute html =~ "hero-chevron-down-mini"
    end
  end
end
