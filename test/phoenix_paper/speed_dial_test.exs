defmodule PhoenixPaper.SpeedDialTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.SpeedDial

  defp dial(assigns) do
    ~H"""
    <.pp_speed_dial id="create" label="Create" class="fixed bottom-6 right-6">
      <:action label="New workbook" navigate="/workbooks/new">
        <span class="hero-document-plus" />
      </:action>
      <:action label="Invite" on_click="open_invite">
        <span class="hero-user-plus" />
      </:action>
    </.pp_speed_dial>
    """
  end

  test "renders a toggle checkbox wired to the trigger label, with the label as its accessible name" do
    html = render_component(&dial/1)

    assert html =~ ~s(id="create-toggle")
    assert html =~ ~s(for="create-toggle")
    assert html =~ ~s(aria-label="Create")
    assert html =~ "peer sr-only"
  end

  test "merges the caller class onto the trigger (for corner anchoring) and defaults to hero-plus" do
    html = render_component(&dial/1)

    assert html =~ "fixed"
    assert html =~ "bottom-6"
    assert html =~ "right-6"
    assert html =~ "hero-plus"
    assert html =~ "peer-checked:rotate-45"
  end

  test "opens on checkbox, hover, or keyboard focus (pure CSS, no JS)" do
    html = render_component(&dial/1)

    assert html =~ "peer-checked:opacity-100"
    assert html =~ "group-hover:opacity-100"
    assert html =~ "group-focus-within:opacity-100"
    refute html =~ "phx-hook"
  end

  test "an action with navigate renders a link; one without renders a button with phx-click" do
    html = render_component(&dial/1)

    assert html =~ ~s(<a)
    assert html =~ ~s(href="/workbooks/new")
    assert html =~ ~s(phx-click="open_invite")
    assert html =~ "New workbook"
    assert html =~ "hero-user-plus"
  end

  test "direction=\"left\" fans the actions out to the left" do
    html = render_component(&left/1)
    assert html =~ "right-full"
    assert html =~ "flex-row-reverse"
    refute html =~ "bottom-full"
  end

  defp left(assigns) do
    ~H"""
    <.pp_speed_dial id="d" label="More" direction="left">
      <:action label="One"><span class="hero-star" /></:action>
    </.pp_speed_dial>
    """
  end

  test "open_icon cross-fades instead of rotating" do
    html = render_component(&with_open_icon/1)

    assert html =~ "hero-bars-3"
    assert html =~ "hero-x-mark"
    assert html =~ "peer-checked:opacity-0"
    refute html =~ "peer-checked:rotate-45"
  end

  defp with_open_icon(assigns) do
    ~H"""
    <.pp_speed_dial id="d" label="Menu">
      <:icon><span class="hero-bars-3" /></:icon>
      <:open_icon><span class="hero-x-mark" /></:open_icon>
      <:action label="One"><span class="hero-star" /></:action>
    </.pp_speed_dial>
    """
  end

  test "default_open checks the toggle" do
    html = render_component(&open/1)
    assert html =~ ~r/id="o-toggle"[^>]*checked/ or html =~ ~r/checked[^>]*id="o-toggle"/
  end

  defp open(assigns) do
    ~H"""
    <.pp_speed_dial id="o" label="X" default_open>
      <:action label="One"><span class="hero-star" /></:action>
    </.pp_speed_dial>
    """
  end

  test "ripple={false}: no onclick handlers anywhere" do
    html = render_component(&no_ripple/1)
    refute html =~ "onclick="
  end

  defp no_ripple(assigns) do
    ~H"""
    <.pp_speed_dial id="d" label="X" ripple={false}>
      <:action label="One" navigate="/x"><span class="hero-star" /></:action>
    </.pp_speed_dial>
    """
  end

  test "paperize={false}: drops built-in styling, keeps the toggle structure" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-secondary"
    refute html =~ "pp-elevation-6"
    assert html =~ "peer sr-only"
    assert html =~ "my-dial"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_speed_dial id="d" label="X" paperize={false} class="my-dial">
      <:action label="One"><span class="hero-star" /></:action>
    </.pp_speed_dial>
    """
  end
end
