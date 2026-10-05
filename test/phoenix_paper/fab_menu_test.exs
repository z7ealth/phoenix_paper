defmodule PhoenixPaper.FabMenuTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.FabMenu

  defp menu(assigns) do
    ~H"""
    <.pp_fab_menu id="create" label="Create" color={@color} size={@size}>
      <:item icon="hero-document" label="Document" navigate="/docs/new" />
      <:item icon="hero-photo" label="Photo" on_click="upload" />
    </.pp_fab_menu>
    """
  end

  test "checkbox, click-away scrim, items and the FAB label are siblings wired to one checkbox" do
    html = render_component(&menu/1, color: "primary", size: "default")

    assert html =~ ~s(id="create-toggle")
    assert html =~ ~s(aria-controls="create-items")
    assert html =~ ~s(id="create-scrim")
    assert html =~ "peer-checked:block"
    assert html =~ ~s(role="menu")
    assert html =~ ~s(role="menuitem")
    assert html =~ ~s(href="/docs/new")
    assert html =~ ~s(phx-click="upload")
    assert html =~ "onkeydown="
  end

  test "primary family: container FAB, primary close button, container items" do
    html = render_component(&menu/1, color: "primary", size: "default")

    assert html =~
             "bg-pp-primary-container text-pp-on-primary-container peer-checked:bg-pp-primary"

    assert html =~ "rounded-[28px] px-6"
    assert html =~ "hero-x-mark"
  end

  test "larger FABs collapse to the 56dp close button" do
    html = render_component(&menu/1, color: "tertiary", size: "large")
    assert html =~ "size-24 rounded-pp-xl"
    assert html =~ "peer-checked:size-14"
    assert html =~ "bg-pp-tertiary-container"
  end

  test "items stagger in" do
    html = render_component(&menu/1, color: "primary", size: "default")
    assert html =~ "delay-0"
    assert html =~ "delay-[30ms]"
  end
end
