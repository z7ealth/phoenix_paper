defmodule PhoenixPaper.HookTest do
  # Not async: flips application env.
  use ExUnit.Case, async: false

  use Phoenix.Component
  import Phoenix.LiveViewTest

  setup do
    on_exit(fn -> Application.delete_env(:phoenix_paper, :hook) end)
  end

  test "Helpers.hook/1 is nil unless the app opted in, and needs an id" do
    assert PhoenixPaper.Helpers.hook("x") == nil

    Application.put_env(:phoenix_paper, :hook, true)
    assert PhoenixPaper.Helpers.hook("x") == "PhoenixPaper"
    assert PhoenixPaper.Helpers.hook(nil) == nil
  end

  test "with the hook enabled, components render phx-hook" do
    Application.put_env(:phoenix_paper, :hook, true)
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhoenixPaper.Tabs.pp_tabs id="t"><span /></PhoenixPaper.Tabs.pp_tabs>
      <PhoenixPaper.TopAppBar.pp_top_app_bar id="bar">A</PhoenixPaper.TopAppBar.pp_top_app_bar>
      <PhoenixPaper.TopAppBar.pp_top_app_bar>B</PhoenixPaper.TopAppBar.pp_top_app_bar>
      """)

    assert length(String.split(html, ~s(phx-hook="PhoenixPaper"))) == 3
  end

  test "menus, split buttons and tooltips (with an id) carry the hook for edge flipping" do
    Application.put_env(:phoenix_paper, :hook, true)
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhoenixPaper.Menu.pp_menu id="m" trigger_icon="hero-bars-3" trigger_label="M"><span /></PhoenixPaper.Menu.pp_menu>
      <PhoenixPaper.Tooltip.pp_tooltip id="t" title="Hi"><b>x</b></PhoenixPaper.Tooltip.pp_tooltip>
      <PhoenixPaper.Tooltip.pp_tooltip title="No id"><b>y</b></PhoenixPaper.Tooltip.pp_tooltip>
      """)

    assert html =~ ~r/id="m"[^>]*phx-hook="PhoenixPaper"/
    assert html =~ ~r/phx-hook="PhoenixPaper"[^>]*id="t"|id="t"[^>]*phx-hook="PhoenixPaper"/
    assert length(String.split(html, ~s(phx-hook="PhoenixPaper"))) == 3
  end
end
