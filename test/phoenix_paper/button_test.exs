defmodule PhoenixPaper.ButtonTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Button

  test "paperize (default): renders Material classes and merges caller class" do
    html = render_component(&raised_primary/1)

    assert html =~ "bg-pp-primary"
    assert html =~ "pp-elevation-2"
    assert html =~ "border-4"
    assert html =~ "Save"
  end

  defp raised_primary(assigns) do
    ~H"""
    <.pp_button class="border-4">Save</.pp_button>
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-primary"
    refute html =~ "rounded-full"
    assert html =~ "my-custom-class"
    assert html =~ "Save"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_button paperize={false} class="my-custom-class">Save</.pp_button>
    """
  end

  test "disabled sets the disabled attribute" do
    html = render_component(&disabled/1)
    assert html =~ "disabled"
  end

  defp disabled(assigns) do
    ~H"""
    <.pp_button disabled>Save</.pp_button>
    """
  end

  test "ripple (default): wires the click handler and the relative/overflow-hidden container classes" do
    html = render_component(&raised_primary/1)

    assert html =~ "onclick="
    assert html =~ "relative"
    assert html =~ "overflow-hidden"
  end

  test "ripple={false}: no click handler, no container classes" do
    html = render_component(&no_ripple/1)

    refute html =~ "onclick="
    refute html =~ "overflow-hidden"
  end

  defp no_ripple(assigns) do
    ~H"""
    <.pp_button ripple={false}>Save</.pp_button>
    """
  end

  test "shows a pointer cursor on hover (browsers default <button> to cursor:default, not pointer)" do
    html = render_component(&raised_primary/1)
    assert html =~ "cursor-pointer"
  end
end
