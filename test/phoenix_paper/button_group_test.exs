defmodule PhoenixPaper.ButtonGroupTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ButtonGroup
  import PhoenixPaper.Button

  test "standard (default): spaced group with the press-expand utility and size vars" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_button_group aria-label="Actions">
        <.pp_button>One</.pp_button>
        <.pp_button>Two</.pp_button>
      </.pp_button_group>
      """)

    assert html =~ ~s(role="group")
    assert html =~ "pp-button-group-standard"
    assert html =~ "gap-3"
    assert html =~ "[--pp-group-pad:16px]"
  end

  test "connected: the connected utility with per-size radii" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_button_group variant="connected" size="md">
        <.pp_button size="md" group="v" selected>Day</.pp_button>
        <.pp_button size="md" group="v" selected={false}>Week</.pp_button>
      </.pp_button_group>
      """)

    assert html =~ "pp-button-group-connected"
    assert html =~ "[--pp-group-outer:28px]"
    assert html =~ ~s(data-pp-toggle-group="v")
    assert html =~ ~s(aria-pressed="true")
  end

  test "full_width shares the width" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_button_group full_width><.pp_button>A</.pp_button></.pp_button_group>"
      )

    assert html =~ "[&amp;&gt;*]:flex-1"
  end

  test "paperize={false} drops the group classes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_button_group paperize={false} class='mine'><span>x</span></.pp_button_group>"
      )

    refute html =~ "pp-button-group"
    assert html =~ "mine"
  end
end
