defmodule PhoenixPaper.NavigationBarTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.NavigationBar

  test "a surface-container bar with active indicator and labels" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_navigation_bar position="fixed">
        <.pp_navigation_bar_item icon="hero-home" active_icon="hero-home-solid" label="Home" navigate="/" active />
        <.pp_navigation_bar_item icon="hero-bell" label="Alerts" navigate="/alerts" badge={3} />
      </.pp_navigation_bar>
      """)

    assert html =~ ~s(data-pp-component="navigation-bar")
    assert html =~ "bg-pp-surface-container"
    assert html =~ "fixed inset-x-0 bottom-0 z-20"
    assert html =~ "h-16"
    assert html =~ ~s(aria-current="page")
    assert html =~ "bg-pp-secondary-container"
    assert html =~ "hero-home-solid"
    assert html =~ ~r/min-w-4[^>]*>\s*3\s*</
  end

  test "item_layout drives horizontal items through the group data attribute" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_navigation_bar item_layout="horizontal">
        <.pp_navigation_bar_item icon="hero-home" label="Home" navigate="/" />
      </.pp_navigation_bar>
      """)

    assert html =~ ~s(data-pp-layout="horizontal")
    assert html =~ "group-data-[pp-layout=horizontal]/bar:flex-row"
    assert html =~ "sm:group-data-[pp-layout=responsive]/bar:flex-row"
  end
end
