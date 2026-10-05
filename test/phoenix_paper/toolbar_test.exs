defmodule PhoenixPaper.ToolbarTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Toolbar

  test "docked (default): full-width standard toolbar" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_toolbar position='fixed' label='Actions'><button>a</button></.pp_toolbar>"
      )

    assert html =~ ~s(role="toolbar")
    assert html =~ ~s(aria-label="Actions")
    assert html =~ "bg-pp-surface-container text-pp-on-surface"
    assert html =~ "fixed inset-x-0 bottom-0 z-20"
  end

  test "floating vibrant vertical pill with a FAB" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_toolbar variant="floating" color="vibrant" orientation="vertical">
        <button>a</button>
        <:fab><span id="fab" /></:fab>
      </.pp_toolbar>
      """)

    assert html =~ "bg-pp-primary-container text-pp-on-primary-container"
    assert html =~ "rounded-pp-full"
    assert html =~ "pp-elevation-3"
    assert html =~ ~s(aria-orientation="vertical")
    assert html =~ "flex-col px-2 py-4"
    assert html =~ ~s(id="fab")
  end
end
