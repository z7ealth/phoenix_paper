defmodule PhoenixPaper.ThemeToggleTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ThemeToggle

  test "renders a switch that computes the effective theme and flips to the opposite, explicitly" do
    html = render_component(&basic/1)

    assert html =~ "Dark mode"
    assert html =~ "querySelector(&quot;html&quot;)"
    assert html =~ "setAttribute(&#39;data-theme&#39;"
    assert html =~ "matchMedia(&#39;(prefers-color-scheme: dark)&#39;)"
    assert html =~ "isDark?&#39;light&#39;:&#39;dark&#39;"
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

  test "on_toggle's JS commands are wired as phx-click, independent of the onclick data-theme flip" do
    html = render_component(&with_on_toggle/1)
    assert html =~ "save_theme_preference"
    assert html =~ "setAttribute(&#39;data-theme&#39;"
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

  test "renders a sun icon and a moon icon inside the thumb" do
    html = render_component(&basic/1)

    assert html =~ "hero-sun-mini"
    assert html =~ "hero-moon-mini"
  end

  test "the icon size override uses !important — Tails doesn't recognize size-* as a conflict group" do
    html = render_component(&basic/1)
    assert html =~ "!size-3"
  end

  test "renders no inline <script> — the first-paint system sync is pure CSS, not JS" do
    html = render_component(&basic/1)
    refute html =~ "<script>"
  end

  test "the click handler never reads the checkbox's own checked property to decide direction" do
    html = render_component(&basic/1)
    refute html =~ "this.checked"
  end
end
