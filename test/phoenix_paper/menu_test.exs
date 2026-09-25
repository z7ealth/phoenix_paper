defmodule PhoenixPaper.MenuTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Menu

  test "renders the trigger and a hidden, anchored popover panel sharing the same id" do
    html = render_component(&menu/1)

    assert html =~ ~s(id="profile-menu-trigger")
    assert html =~ ~s(id="profile-menu-panel")
    assert html =~ ~s(aria-controls="profile-menu-panel")
    assert html =~ "hidden"
    assert html =~ "Open menu"
    assert html =~ "Profile"
    assert html =~ "Log out"
  end

  defp menu(assigns) do
    ~H"""
    <.pp_menu id="profile-menu">
      <:trigger>Open menu</:trigger>
      <div>Profile</div>
      <div>Log out</div>
    </.pp_menu>
    """
  end

  test "the trigger's phx-click wires the toggle JS command, targeting this menu's panel" do
    html = render_component(&menu/1)

    assert html =~ "phx-click"
    assert html =~ "toggle"
    assert html =~ "profile-menu-panel"
  end

  test "toggle/1 and close/1 return JS commands targeting the given id" do
    assert %Phoenix.LiveView.JS{} = PhoenixPaper.Menu.toggle("profile-menu")
    assert %Phoenix.LiveView.JS{} = PhoenixPaper.Menu.close("profile-menu")

    toggle_json = Jason.encode!(PhoenixPaper.Menu.toggle("profile-menu"))
    assert toggle_json =~ "profile-menu-panel"
    assert toggle_json =~ "profile-menu-trigger"
    assert toggle_json =~ "aria-expanded"

    close_json = Jason.encode!(PhoenixPaper.Menu.close("profile-menu"))
    assert close_json =~ "profile-menu-panel"
    assert close_json =~ "aria-expanded"
  end

  test "panel wires phx-click-away and Escape to close/1, and phx-click to close on item selection" do
    html = render_component(&menu/1)

    assert html =~ "phx-click-away"
    assert html =~ ~s(phx-key="escape")
    assert html =~ "phx-window-keydown"
  end

  test "anchor (default bottom-start) positions the panel below-left of the trigger" do
    html = render_component(&menu/1)

    assert html =~ "top-full"
    assert html =~ "left-0"
  end

  test "anchor=\"top-end\" flips to above-right" do
    html = render_component(&top_end/1)

    assert html =~ "bottom-full"
    assert html =~ "right-0"
  end

  defp top_end(assigns) do
    ~H"""
    <.pp_menu id="profile-menu" anchor="top-end">
      <:trigger>Open menu</:trigger>
      Item
    </.pp_menu>
    """
  end

  test "paperize (default): renders the Paper surface classes on the panel" do
    html = render_component(&menu/1)

    assert html =~ "bg-pp-surface"
    assert html =~ "pp-elevation-8"
  end

  test "paperize={false}: drops the surface/cosmetic classes but keeps positioning" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-surface"
    refute html =~ "min-w-"
    assert html =~ "top-full"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_menu id="profile-menu" paperize={false} class="my-class">
      <:trigger>Open menu</:trigger>
      Item
    </.pp_menu>
    """
  end

  describe "trigger" do
    test "is a pp_button (icon variant by default) carrying the toggle wiring" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_menu id="m"><:trigger>T</:trigger>items</.pp_menu>
        """)

      [trigger] = Regex.run(~r/<button[^>]*id="m-trigger"[^>]*>/, html)
      assert trigger =~ ~s(data-pp-component="button")
      assert trigger =~ ~s(data-pp-variant="icon")
      assert trigger =~ "text-pp-primary hover:bg-pp-primary/10"
      assert trigger =~ ~s(aria-haspopup="true")
      assert trigger =~ ~s(aria-expanded="false")
      assert trigger =~ ~s(aria-controls="m-panel")
      assert trigger =~ "phx-click="
      assert trigger =~ "m-panel"
    end

    test "trigger_variant/color/size/class pass through to the button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_menu
          id="m"
          trigger_variant="outlined"
          trigger_color="inherit"
          trigger_size="small"
          trigger_class="mine"
        >
          <:trigger>Export</:trigger>
          items
        </.pp_menu>
        """)

      [trigger] = Regex.run(~r/<button[^>]*id="m-trigger"[^>]*>/, html)
      assert trigger =~ ~s(data-pp-variant="outlined")
      assert trigger =~ "border-current"
      assert trigger =~ "text-xs"
      assert trigger =~ "mine"
    end

    test "trigger_variant=none keeps the bare button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_menu id="m" trigger_variant="none" trigger_class="mine"><:trigger>T</:trigger>i</.pp_menu>
        """)

      [trigger] = Regex.run(~r/<button[^>]*id="m-trigger"[^>]*>/, html)
      assert trigger =~ ~s(class="cursor-pointer mine")
      refute trigger =~ "data-pp-component"
      assert trigger =~ "phx-click="
    end
  end
end
