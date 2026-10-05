defmodule PhoenixPaper.MenuTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Menu

  defp menu(assigns) do
    ~H"""
    <.pp_menu id="m" trigger_icon="hero-ellipsis-vertical" trigger_label="More" anchor={@anchor} color={@color}>
      <.pp_menu_item icon="hero-pencil" trailing_text="⌘E" phx-click="edit">Edit</.pp_menu_item>
      <.pp_menu_item selected supporting_text="Current">Grid</.pp_menu_item>
      <.pp_menu_item navigate="/trash" disabled>Trash</.pp_menu_item>
    </.pp_menu>
    """
  end

  test "an icon-button trigger with the toggle wiring and a hidden panel" do
    html = render_component(&menu/1, anchor: "bottom-start", color: "standard")

    assert html =~ ~s(id="m-trigger")
    assert html =~ ~s(aria-label="More")
    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(aria-controls="m-panel")
    assert html =~ ~s(id="m-panel")
    assert html =~ "absolute z-40 hidden"
    assert html =~ "top-full start-0 mt-1"
  end

  test "the panel is the Expressive menu surface; vibrant uses tertiary-container" do
    standard = render_component(&menu/1, anchor: "bottom-start", color: "standard")
    vibrant = render_component(&menu/1, anchor: "top-end", color: "vibrant")

    assert standard =~ "rounded-pp-lg bg-pp-surface-container p-1"
    assert standard =~ "pp-elevation-2"
    assert vibrant =~ "bg-pp-tertiary-container"
    assert vibrant =~ "bottom-full end-0 mb-1"
  end

  test "items: icon, shortcut, supporting text, selected and disabled" do
    html = render_component(&menu/1, anchor: "bottom-start", color: "standard")

    assert html =~ ~s(role="menuitem")
    assert html =~ "⌘E"
    assert html =~ "Current"
    assert html =~ ~s(role="menuitemradio")
    assert html =~ ~s(aria-checked="true")
    assert html =~ "bg-pp-secondary-container"
    assert html =~ ~s(aria-disabled="true")
    assert html =~ "min-h-12"
  end

  test "panel closes on click-away, Escape and item clicks" do
    html = render_component(&menu/1, anchor: "bottom-start", color: "standard")

    assert html =~ "phx-click-away"
    assert html =~ ~s(phx-key="escape")
    assert html =~ "phx-window-keydown"
  end

  test "toggle/1 and close/1 return JS commands for the id" do
    assert toggle("m").ops == [
             ["toggle", %{to: "#m-panel", display: "flex"}],
             ["toggle_attr", %{to: "#m-trigger", attr: ["aria-expanded", "true", "false"]}]
           ]

    assert close("m").ops == [
             ["hide", %{to: "#m-panel"}],
             ["set_attr", %{to: "#m-trigger", attr: ["aria-expanded", "false"]}],
             [
               "set_attr",
               %{to: "#m-panel [aria-haspopup=menu]", attr: ["aria-expanded", "false"]}
             ]
           ]
  end

  test "a button trigger takes the :trigger slot and a chevron; none keeps a bare button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_menu id="a" trigger_variant="tonal"><:trigger>Sort</:trigger><span /></.pp_menu>
      <.pp_menu id="b" trigger_variant="none" trigger_class="mine"><:trigger>Bare</:trigger><span /></.pp_menu>
      """)

    assert html =~ "Sort"
    assert html =~ "bg-pp-secondary-container"
    assert html =~ "hero-chevron-down"
    assert html =~ ~s(class="cursor-pointer mine")
  end

  test "paperize={false} keeps positioning, drops the surface" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_menu id="p" trigger_icon="hero-bars-3" trigger_label="M" paperize={false} class="mine"><span /></.pp_menu>
      """)

    assert html =~ "absolute z-40 hidden"
    refute html =~ "bg-pp-surface-container"
    assert html =~ "mine"
  end

  test "pp_submenu: a chevron item whose panel opens beside it on hover/focus, click focuses into it" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_submenu id="share" label="Share" icon="hero-share">
        <.pp_menu_item phx-click="email">Email</.pp_menu_item>
      </.pp_submenu>
      """)

    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(aria-controls="share-panel")
    assert html =~ "hero-chevron-right"
    assert html =~ "group-hover/sub:flex group-focus-within/sub:flex"
    assert html =~ "start-full ps-1"
    assert html =~ "focus_first"
    assert html =~ "Email"
  end
end
