defmodule PhoenixPaper.SearchBarTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.SearchBar

  test "a 56dp pill with a search icon and a named search input" do
    assigns = %{}

    html =
      rendered_to_string(~H"<.pp_search_bar name='q' value='mail' placeholder='Search mail' />")

    assert html =~ ~s(type="search")
    assert html =~ ~s(name="q")
    assert html =~ ~s(value="mail")
    assert html =~ ~s(aria-label="Search mail")
    assert html =~ "h-14"
    assert html =~ "rounded-[28px] bg-pp-surface-container-high"
    assert html =~ "hero-magnifying-glass"
    refute html =~ "combobox"
  end

  test "results: the docked search view opens on focus-within" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_search_bar id="s" name="q">
        <:results><p>Hit</p></:results>
      </.pp_search_bar>
      """)

    assert html =~ ~s(role="combobox")
    assert html =~ ~s(aria-controls="s-results")
    assert html =~ "group-focus-within/search:visible"
    assert html =~ "group-focus-within/search:rounded-b-none"
    assert html =~ "Hit"
  end

  test "leading/trailing slots replace the icon and add actions" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_search_bar>
        <:leading><button id="menu">m</button></:leading>
        <:trailing><span id="avatar" /></:trailing>
      </.pp_search_bar>
      """)

    assert html =~ ~s(id="menu")
    assert html =~ ~s(id="avatar")
    refute html =~ "hero-magnifying-glass"
  end

  test "fullscreen view lifts into a fixed layer with a back button; responsive only below sm" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_search_bar id="f" view="fullscreen"><:results><p>Hit</p></:results></.pp_search_bar>
      <.pp_search_bar id="r" view="responsive"><:results><p>Hit</p></:results></.pp_search_bar>
      """)

    assert html =~ "focus-within:fixed focus-within:inset-0 focus-within:z-50"
    assert html =~ ~s(aria-label="Back")
    assert html =~ "group-focus-within/search:h-[72px]"
    assert html =~ "max-sm:focus-within:fixed"
    assert html =~ "sm:group-focus-within/search:rounded-b-none"
  end
end
