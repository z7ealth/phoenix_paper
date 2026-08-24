defmodule PhoenixPaper.DrawerTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Drawer

  test "renders the toggle checkbox, backdrop label and drawer sharing the same toggle id" do
    html = render_component(&drawer/1)

    assert html =~ ~s(id="app-drawer-toggle")
    assert html =~ ~s(for="app-drawer-toggle")
    assert html =~ "Home"
  end

  defp drawer(assigns) do
    ~H"""
    <.pp_drawer id="app-drawer">
      <:header>My App</:header>
      Home
    </.pp_drawer>
    """
  end

  test "pp_drawer_toggle points its label at the same derived toggle id" do
    html = render_component(&toggle/1)
    assert html =~ ~s(for="app-drawer-toggle")
  end

  defp toggle(assigns) do
    ~H"""
    <.pp_drawer_toggle for="app-drawer" />
    """
  end

  test "paperize={false} on the drawer drops built-in classes but keeps the toggle mechanism" do
    html = render_component(&bare/1)

    refute html =~ "peer-checked:translate-x-0"
    assert html =~ ~s(id="app-drawer-toggle")
    assert html =~ "my-drawer"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_drawer id="app-drawer" paperize={false} class="my-drawer">Home</.pp_drawer>
    """
  end
end
