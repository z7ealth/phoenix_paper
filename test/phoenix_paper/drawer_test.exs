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

  test "color defaults to surface, unchanged from before the attr existed" do
    html = render_component(&drawer/1)
    assert html =~ "bg-pp-surface"
    assert html =~ "text-pp-on-surface"
  end

  test "color=\"primary\" paints the panel and restyles nested list-item/list-subheader/divider contrast" do
    html = render_component(&colored/1)

    assert html =~ "bg-pp-primary"
    assert html =~ "text-pp-on-primary"
    assert html =~ "[data-pp-component=list-subheader]]:text-pp-on-primary/70"
    assert html =~ "[data-pp-component=divider]]:border-pp-on-primary/20"
    assert html =~ "[data-pp-component=list-item]]:text-pp-on-primary"
    assert html =~ "[data-pp-component=list-item][aria-current=page]]:bg-pp-on-primary/15"
  end

  defp colored(assigns) do
    ~H"""
    <.pp_drawer id="app-drawer" color="primary">
      <:header>My App</:header>
      Home
    </.pp_drawer>
    """
  end

  test "width defaults to md (w-64), unchanged from before the attr existed" do
    html = render_component(&drawer/1)

    assert html =~ "w-64"
    assert html =~ "lg:w-64"
  end

  test "width=\"xl\" widens both the mobile and desktop panel together" do
    html = render_component(&wide/1)

    assert html =~ "w-80"
    assert html =~ "lg:w-80"
    refute html =~ "w-64"
  end

  defp wide(assigns) do
    ~H"""
    <.pp_drawer id="app-drawer" width="xl">Home</.pp_drawer>
    """
  end

  test "backdrop reveal is scoped to max-lg, not a separate lg:hidden that a peer-checked: specificity fight could beat" do
    html = render_component(&drawer/1)

    assert html =~ "max-lg:peer-checked:block"
    refute html =~ "peer-checked:block lg:hidden"
  end
end
