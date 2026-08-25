defmodule PhoenixPaper.ThemeToggleTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ThemeToggle

  test "renders a switch wired to toggle data-theme on html by default" do
    html = render_component(&basic/1)

    assert html =~ "Dark mode"
    assert html =~ "toggle_attr"
    assert html =~ "data-theme"
    assert html =~ "dark"
    assert html =~ "html"
  end

  defp basic(assigns) do
    ~H"""
    <.pp_theme_toggle />
    """
  end

  test "default_checked sets the switch's initial visual state" do
    html = render_component(&checked/1)
    assert html =~ "checked"
  end

  defp checked(assigns) do
    ~H"""
    <.pp_theme_toggle default_checked={true} />
    """
  end

  test "target scopes the toggle to a custom selector instead of html" do
    html = render_component(&scoped/1)
    assert html =~ "#preview"
  end

  defp scoped(assigns) do
    ~H"""
    <.pp_theme_toggle target="#preview" />
    """
  end

  test "label overrides the default \"Dark mode\" text" do
    html = render_component(&custom_label/1)
    assert html =~ "Light/Dark"
    refute html =~ "Dark mode"
  end

  defp custom_label(assigns) do
    ~H"""
    <.pp_theme_toggle label="Light/Dark" />
    """
  end

  test "on_toggle's JS commands run before the built-in data-theme flip" do
    html = render_component(&with_on_toggle/1)
    assert html =~ "save_theme_preference"
    assert html =~ "toggle_attr"
  end

  defp with_on_toggle(assigns) do
    ~H"""
    <.pp_theme_toggle on_toggle={Phoenix.LiveView.JS.push("save_theme_preference")} />
    """
  end

  test "paperize={false} drops the switch's built-in classes" do
    html = render_component(&bare/1)
    refute html =~ "has-[:checked]"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_theme_toggle paperize={false} />
    """
  end
end
