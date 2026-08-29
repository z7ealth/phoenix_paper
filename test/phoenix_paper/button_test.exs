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

  test "paperize={false}: ripple is off too, even though ripple defaults true — nothing left to size/clip its span" do
    html = render_component(&bare/1)

    refute html =~ "onclick="
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

  test "start_icon and end_icon render around the label" do
    html = render_component(&with_icons/1)

    assert html =~ "hero-trash"
    assert html =~ "hero-arrow-right"
    assert html =~ "Delete"
  end

  defp with_icons(assigns) do
    ~H"""
    <.pp_button>
      <:start_icon><span class="hero-trash" /></:start_icon>
      Delete
      <:end_icon><span class="hero-arrow-right" /></:end_icon>
    </.pp_button>
    """
  end

  test "href renders an <a> instead of a <button>, keeping the Material classes and ripple" do
    html = render_component(&link_button/1)

    assert html =~ ~s(<a)
    refute html =~ ~s(<button)
    assert html =~ ~s(href="/issues")
    assert html =~ "bg-pp-primary"
    assert html =~ "onclick="
    assert html =~ "Issues"
  end

  defp link_button(assigns) do
    ~H"""
    <.pp_button href="/issues">Issues</.pp_button>
    """
  end

  test "navigate/patch also switch to link mode" do
    assert render_component(&nav_button/1) =~ ~s(<a)
    assert render_component(&patch_button/1) =~ ~s(<a)
  end

  defp nav_button(assigns) do
    ~H"""
    <.pp_button navigate="/new">New</.pp_button>
    """
  end

  defp patch_button(assigns) do
    ~H"""
    <.pp_button patch="/tab/2">Tab</.pp_button>
    """
  end

  test "link-mode passes link attrs through and honors disabled without a disabled attribute" do
    html = render_component(&disabled_link/1)

    assert html =~ ~s(method="delete")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ "pointer-events-none"
    refute html =~ "onclick="
  end

  defp disabled_link(assigns) do
    ~H"""
    <.pp_button href="/logout" method="delete" disabled>Sign out</.pp_button>
    """
  end

  test "loading disables the button, drops the ripple handler, and swaps start_icon for a spinner" do
    html = render_component(&loading/1)

    assert html =~ "disabled"
    assert html =~ ~s(aria-busy="true")
    assert html =~ "animate-spin"
    refute html =~ "onclick="
    refute html =~ "hero-trash"
  end

  defp loading(assigns) do
    ~H"""
    <.pp_button loading>
      <:start_icon><span class="hero-trash" /></:start_icon>
      Delete
    </.pp_button>
    """
  end
end
