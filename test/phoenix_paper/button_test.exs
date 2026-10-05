defmodule PhoenixPaper.ButtonTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Button

  alias Phoenix.LiveView.JS

  defp html(assigns \\ %{}, fun), do: rendered_to_string(fun.(assigns))

  test "filled (default): primary container, MD3 small size, state layer, focus ring, round shape" do
    html = html(fn assigns -> ~H"<.pp_button class='extra'>Save</.pp_button>" end)

    assert html =~ "bg-pp-primary text-pp-on-primary"
    assert html =~ "h-10"
    assert html =~ "pp-label-large"
    assert html =~ "pp-state-layer"
    assert html =~ "pp-focus-ring"
    assert html =~ "rounded-[20px]"
    assert html =~ "active:rounded-pp-sm"
    assert html =~ "pp-motion-spatial-fast"
    assert html =~ "cursor-pointer"
    assert html =~ "extra"
    refute html =~ "uppercase"
  end

  test "each variant uses its MD3 roles" do
    html =
      html(fn assigns ->
        ~H"""
        <.pp_button variant="tonal">T</.pp_button>
        <.pp_button variant="elevated">E</.pp_button>
        <.pp_button variant="outlined">O</.pp_button>
        <.pp_button variant="text">X</.pp_button>
        """
      end)

    assert html =~ "bg-pp-secondary-container text-pp-on-secondary-container"

    assert html =~
             "bg-pp-surface-container-low text-pp-primary pp-elevation-1 hover:pp-elevation-2"

    assert html =~ "border border-pp-outline-variant text-pp-primary"
    assert html =~ ~s(class="inline-flex)
  end

  test "color swaps the role: tertiary filled and tonal" do
    html =
      html(fn assigns ->
        ~H"""
        <.pp_button color="tertiary">A</.pp_button>
        <.pp_button variant="tonal" color="tertiary">B</.pp_button>
        """
      end)

    assert html =~ "bg-pp-tertiary text-pp-on-tertiary"
    assert html =~ "bg-pp-tertiary-container text-pp-on-tertiary-container"
  end

  test "color=inherit follows currentColor" do
    html =
      html(fn assigns -> ~H"<.pp_button variant='outlined' color='inherit'>A</.pp_button>" end)

    assert html =~ "border-current/40 text-inherit"
  end

  test "Expressive sizes scale height, padding, type role and icon size" do
    html =
      html(fn assigns ->
        ~H"""
        <.pp_button size="xs">A</.pp_button>
        <.pp_button size="md">B</.pp_button>
        <.pp_button size="xl">C</.pp_button>
        """
      end)

    assert html =~ "h-8 gap-1 px-3"
    assert html =~ "h-14 gap-2 px-6 pp-title-medium"
    assert html =~ "h-[8.5rem]"
    assert html =~ "pp-headline-large"
  end

  test "square shape uses the corner scale and still morphs on press" do
    html = html(fn assigns -> ~H"<.pp_button shape='square' size='md'>A</.pp_button>" end)
    assert html =~ "rounded-pp-lg active:rounded-pp-md"
  end

  test "selected makes it a toggle button: aria-pressed, toggle colors, round→square morph" do
    html = html(fn assigns -> ~H"<.pp_button selected>Bold</.pp_button>" end)

    assert html =~ ~s(aria-pressed="true")
    assert html =~ "bg-pp-surface-container text-pp-on-surface-variant"
    assert html =~ "aria-pressed:bg-pp-primary"
    assert html =~ "aria-pressed:rounded-pp-md"
    refute html =~ "phx-click"
  end

  test "a plain button has no aria-pressed" do
    html = html(fn assigns -> ~H"<.pp_button>Save</.pp_button>" end)
    refute html =~ "aria-pressed"
  end

  test "toggle wires the client-side JS toggle; group makes it exclusive" do
    html =
      html(fn assigns ->
        ~H"""
        <.pp_button toggle selected={false}>B</.pp_button>
        <.pp_button group="view">Day</.pp_button>
        """
      end)

    assert html =~ ~s(aria-pressed="false")
    assert html =~ "toggle_attr"
    assert html =~ ~s(data-pp-toggle-group="view")
    assert html =~ "set_attr"
  end

  test "PhoenixPaper.Toggle.js builds the exact op chains" do
    assert PhoenixPaper.Toggle.js(nil, JS.push("x")).ops == [
             ["toggle_attr", %{attr: ["aria-pressed", "true", "false"]}],
             ["push", %{event: "x"}]
           ]

    assert PhoenixPaper.Toggle.js("v").ops == [
             ["set_attr", %{to: ~s([data-pp-toggle-group="v"]), attr: ["aria-pressed", "false"]}],
             ["set_attr", %{attr: ["aria-pressed", "true"]}]
           ]
  end

  test "disabled uses MD3's disabled colors" do
    html = html(fn assigns -> ~H"<.pp_button disabled>Save</.pp_button>" end)

    assert html =~ "disabled"
    assert html =~ "disabled:bg-pp-on-surface/10"
    assert html =~ "disabled:text-pp-on-surface/38"
  end

  test "ripple (default) wires the click handler and the container classes; ripple false drops the handler" do
    on = html(fn assigns -> ~H"<.pp_button>Save</.pp_button>" end)
    off = html(fn assigns -> ~H"<.pp_button ripple={false}>Save</.pp_button>" end)

    assert on =~ "onclick="
    assert on =~ "relative overflow-hidden"
    refute off =~ "onclick="
  end

  test "paperize={false}: no built-in classes and no ripple" do
    html = html(fn assigns -> ~H"<.pp_button paperize={false} class='mine'>Save</.pp_button>" end)

    refute html =~ "bg-pp-primary"
    refute html =~ "onclick="
    assert html =~ "mine"
  end

  test "start_icon and end_icon render around the label" do
    html =
      html(fn assigns ->
        ~H"""
        <.pp_button>
          <:start_icon><span id="s" /></:start_icon>
          Label
          <:end_icon><span id="e" /></:end_icon>
        </.pp_button>
        """
      end)

    assert html =~ ~s(id="s")
    assert html =~ ~s(id="e")
  end

  test "href/navigate/patch render a link with the same look; disabled becomes aria-disabled" do
    html =
      html(fn assigns ->
        ~H"""
        <.pp_button href="/a" target="_blank">A</.pp_button>
        <.pp_button navigate="/b" disabled>B</.pp_button>
        """
      end)

    assert html =~ ~s(href="/a")
    assert html =~ ~s(target="_blank")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ "aria-disabled:text-pp-on-surface/38"
    refute html =~ "<button"
  end

  test "loading disables, drops the ripple and shows a spinner instead of start_icon" do
    html =
      html(fn assigns ->
        ~H"""
        <.pp_button loading>
          <:start_icon><span id="s" /></:start_icon>
          Save
        </.pp_button>
        """
      end)

    assert html =~ "disabled"
    assert html =~ "animate-spin"
    assert html =~ ~s(aria-busy="true")
    refute html =~ ~s(id="s")
    refute html =~ "onclick="
  end

  test "position emits exactly one position class" do
    html = html(fn assigns -> ~H"<.pp_button position='fixed'>A</.pp_button>" end)

    assert html =~ "fixed overflow-hidden"
    refute html =~ "relative overflow-hidden"
  end
end
