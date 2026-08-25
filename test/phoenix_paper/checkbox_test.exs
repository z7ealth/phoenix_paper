defmodule PhoenixPaper.CheckboxTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Checkbox

  test "renders the hidden-input trick and the checked box when true" do
    html = render_component(&checked/1)

    assert html =~ ~s(type="hidden")
    assert html =~ ~s(type="checkbox")
    assert html =~ "checked"
    assert html =~ "Accept terms"
  end

  defp checked(assigns) do
    ~H"""
    <.pp_checkbox checked={true} label="Accept terms" />
    """
  end

  test "paperize={false} renders a bare native checkbox, no hidden input" do
    html = render_component(&bare/1)

    refute html =~ ~s(type="hidden")
    assert html =~ ~s(type="checkbox")
  end

  defp bare(assigns) do
    ~H"""
    <.pp_checkbox paperize={false} label="Bare" />
    """
  end

  test "ripple (default): wires the click handler on the box" do
    html = render_component(&checked/1)
    assert html =~ "onclick="
  end

  test "ripple={false}: no click handler" do
    html = render_component(&no_ripple/1)
    refute html =~ "onclick="
  end

  defp no_ripple(assigns) do
    ~H"""
    <.pp_checkbox ripple={false} />
    """
  end

  test "paperize={false}: no click handler either, even though ripple defaults true" do
    html = render_component(&bare/1)
    refute html =~ "onclick="
  end
end
