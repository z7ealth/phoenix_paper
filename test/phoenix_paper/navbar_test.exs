defmodule PhoenixPaper.NavbarTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Navbar

  test "renders title, leading and actions slots with the default primary color" do
    html = render_component(&navbar/1)

    assert html =~ "bg-pp-primary"
    assert html =~ "My App"
    assert html =~ "Menu"
    assert html =~ "Bell"
  end

  defp navbar(assigns) do
    ~H"""
    <.pp_navbar>
      <:leading>Menu</:leading>
      My App
      <:actions>Bell</:actions>
    </.pp_navbar>
    """
  end

  test "sticky position adds top-0 and a z-index" do
    html = render_component(&sticky/1)
    assert html =~ "sticky"
    assert html =~ "top-0"
  end

  defp sticky(assigns) do
    ~H"""
    <.pp_navbar position="sticky">Title</.pp_navbar>
    """
  end

  test "paperize={false} drops built-in classes" do
    html = render_component(&bare/1)
    refute html =~ "bg-pp-primary"
    assert html =~ "my-navbar"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_navbar paperize={false} class="my-navbar">Title</.pp_navbar>
    """
  end
end
