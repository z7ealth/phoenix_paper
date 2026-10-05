defmodule PhoenixPaper.SplitButtonTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.SplitButton
  import PhoenixPaper.Menu, only: [pp_menu_item: 1]

  test "leading and trailing halves, inner corners small, trailing wired to its menu" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_split_button id="send" phx-click="send">
        Send
        <:menu><.pp_menu_item phx-click="schedule">Schedule</.pp_menu_item></:menu>
      </.pp_split_button>
      """)

    assert html =~ ~s(data-pp-component="split-button")
    assert html =~ "gap-0.5"
    assert html =~ "rounded-s-[20px] rounded-e-[4px]"
    assert html =~ "rounded-s-[4px] rounded-e-[20px] aria-expanded:rounded-[20px]"
    assert html =~ ~s(id="send-trigger")
    assert html =~ ~s(aria-controls="send-panel")
    assert html =~ ~s(phx-click="send")
    assert html =~ "[[aria-expanded=true]&gt;&amp;]:rotate-180"
    assert html =~ "Schedule"
    assert html =~ "bg-pp-primary text-pp-on-primary"
  end

  test "variant and size" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_split_button id="s" variant="tonal" size="lg">X<:menu><span /></:menu></.pp_split_button>
      """)

    assert html =~ "bg-pp-secondary-container"
    assert html =~ "h-24"
    assert html =~ "rounded-s-[48px]"
  end
end
