defmodule PhoenixPaper.ChipTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Chip

  test "assist (default): a 32dp outlined button with a primary icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_chip><:icon><span class="hero-calendar" /></:icon>Add to calendar</.pp_chip>
      """)

    assert html =~ "<button"
    assert html =~ "h-8"
    assert html =~ "rounded-pp-sm"
    assert html =~ "border border-pp-outline-variant text-pp-on-surface"
    assert html =~ "text-pp-primary"
    assert html =~ "pp-label-large"
    assert html =~ "pp-state-layer"
    assert html =~ "onclick="
  end

  test "elevated swaps the outline for a fill and shadow" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_chip elevated>A</.pp_chip>")
    assert html =~ "bg-pp-surface-container-low"
    assert html =~ "pp-elevation-1"
  end

  test "filter: a toggle with a check shown when pressed" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_chip variant="filter" toggle selected={false}>Unread</.pp_chip>
      <.pp_chip variant="filter" group="sort" selected>Newest</.pp_chip>
      """)

    assert html =~ ~s(aria-pressed="false")
    assert html =~ ~s(aria-pressed="true")
    assert html =~ "hero-check"
    assert html =~ "[[aria-pressed=false]&gt;&amp;]:hidden"
    assert html =~ "aria-pressed:bg-pp-secondary-container"
    assert html =~ ~s(data-pp-toggle-group="sort")
    assert html =~ "toggle_attr"
  end

  test "input: a static div unless clickable, with a non-nested delete control" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_chip variant="input" deletable on_delete={Phoenix.LiveView.JS.push("remove")}>elixir</.pp_chip>
      """)

    assert html =~ "<div"
    refute html =~ "<button"
    assert html =~ ~s(role="button")
    assert html =~ ~s(data-pp-component="chip-delete")
    assert html =~ "remove"
    assert html =~ "onkeydown="
    assert html =~ "pe-2"
  end

  test "clickable input chips with delete keep the delete as a span, not a nested button" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_chip variant='input' clickable deletable>a</.pp_chip>")

    assert length(String.split(html, "<button")) == 2
  end

  test "selected input chip" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_chip variant='input' selected>a</.pp_chip>")
    assert html =~ "bg-pp-secondary-container"
  end

  test "suggestion" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_chip variant='suggestion'>Sounds good</.pp_chip>")
    assert html =~ "text-pp-on-surface-variant"
    assert html =~ ~s(data-pp-variant="suggestion")
  end

  test "disabled disables the button and takes the delete out of the tab order" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_chip disabled>A</.pp_chip>
      <.pp_chip variant="input" deletable disabled>B</.pp_chip>
      """)

    assert html =~ "disabled"
    assert html =~ ~s(tabindex="-1")
    assert html =~ "disabled:text-pp-on-surface/38"
  end

  test "paperize={false}: no built-in classes" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_chip paperize={false} class='mine'>A</.pp_chip>")
    refute html =~ "rounded-pp-sm"
    refute html =~ "onclick"
    assert html =~ "mine"
  end
end
