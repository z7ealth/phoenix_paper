defmodule PhoenixPaper.AppBarTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.AppBar

  test "renders title, leading and actions slots with the default primary color" do
    html = render_component(&app_bar/1)

    assert html =~ "bg-pp-primary"
    assert html =~ "My App"
    assert html =~ "Menu"
    assert html =~ "Bell"
  end

  defp app_bar(assigns) do
    ~H"""
    <.pp_app_bar>
      <:leading>Menu</:leading>
      My App
      <:actions>Bell</:actions>
    </.pp_app_bar>
    """
  end

  test "sticky position adds top-0 and a z-index" do
    html = render_component(&sticky/1)
    assert html =~ "sticky"
    assert html =~ "top-0"
  end

  defp sticky(assigns) do
    ~H"""
    <.pp_app_bar position="sticky">Title</.pp_app_bar>
    """
  end

  test "position=\"absolute\" and position=\"relative\" render the matching classes" do
    html = render_component(&absolute/1)
    assert html =~ ~r/\babsolute\b/
    assert html =~ "inset-x-0"

    html = render_component(&relative/1)
    assert html =~ ~r/\brelative\b/
    refute html =~ "inset-x-0"
  end

  defp absolute(assigns) do
    ~H"""
    <.pp_app_bar position="absolute">Title</.pp_app_bar>
    """
  end

  defp relative(assigns) do
    ~H"""
    <.pp_app_bar position="relative">Title</.pp_app_bar>
    """
  end

  test "color=\"transparent\" renders no background/text-color classes or elevation shadow" do
    html = render_component(&transparent/1)
    refute html =~ "bg-pp-"
    refute html =~ "text-pp-on-"
    refute html =~ "shadow"
  end

  defp transparent(assigns) do
    ~H"""
    <.pp_app_bar color="transparent">Title</.pp_app_bar>
    """
  end

  test "variant=\"dense\" uses a shorter toolbar row" do
    html = render_component(&dense/1)
    assert html =~ "h-12"
    refute html =~ "h-16"
  end

  defp dense(assigns) do
    ~H"""
    <.pp_app_bar variant="dense">Title</.pp_app_bar>
    """
  end

  test "paperize={false} drops built-in classes" do
    html = render_component(&bare/1)
    refute html =~ "bg-pp-primary"
    assert html =~ "my-app-bar"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_app_bar paperize={false} class="my-app-bar">Title</.pp_app_bar>
    """
  end
end
