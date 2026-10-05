defmodule PhoenixPaper.TooltipTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Tooltip

  test "plain (default): inverse-surface bubble, hidden until hover/focus of its named group" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_tooltip title='Delete'><button>x</button></.pp_tooltip>")

    assert html =~ ~s(role="tooltip")
    assert html =~ "Delete"
    assert html =~ "group/tooltip"
    assert html =~ "bg-pp-inverse-surface"
    assert html =~ "pp-body-small"
    assert html =~ "invisible opacity-0"
    assert html =~ "group-hover/tooltip:visible"
    assert html =~ "group-focus-within/tooltip:opacity-100"
    assert html =~ "group-hover/tooltip:delay-300"
    assert html =~ "pointer-events-none"
  end

  test "nil or empty title renders only the trigger" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_tooltip title={nil}><button>a</button></.pp_tooltip>
      <.pp_tooltip title=""><button>b</button></.pp_tooltip>
      """)

    refute html =~ "role=\"tooltip\""
  end

  test "rich: surface-container card with subhead and actions, interactive" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_tooltip variant="rich" subhead="Autosave" title="Saved as you type.">
        <button>i</button>
        <:actions><a href="/help">Learn more</a></:actions>
      </.pp_tooltip>
      """)

    assert html =~ "bg-pp-surface-container"
    assert html =~ "pp-elevation-2"
    assert html =~ "Autosave"
    assert html =~ "pp-title-small"
    assert html =~ "Learn more"
    assert html =~ "pointer-events-auto"
  end

  test "placement picks the offset; the gap is padding" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_tooltip title="A" placement="bottom"><b>a</b></.pp_tooltip>
      <.pp_tooltip title="B" placement="right"><b>b</b></.pp_tooltip>
      """)

    assert html =~ "top-full left-1/2 -translate-x-1/2 pt-1"
    assert html =~ "left-full top-1/2 -translate-y-1/2 ps-1"
  end

  test "paperize={false}: no built-in bubble classes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_tooltip title='A' paperize={false} class='mine'><b>a</b></.pp_tooltip>"
      )

    refute html =~ "bg-pp-inverse-surface"
    assert html =~ "mine"
    assert html =~ "group/tooltip relative inline-flex"
  end
end
