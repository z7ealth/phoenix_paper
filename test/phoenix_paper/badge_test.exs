defmodule PhoenixPaper.BadgeTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Badge

  test "content renders the large badge in error colors" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_badge content={4}><span>bell</span></.pp_badge>")

    assert html =~ ~s(data-pp-size="large")
    assert html =~ "h-4 min-w-4"
    assert html =~ "pp-label-small"
    assert html =~ "bg-pp-error"
    assert html =~ "text-pp-on-error"
  end

  test "no content renders the small 6dp badge" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_badge><span>chat</span></.pp_badge>")

    assert html =~ ~s(data-pp-size="small")
    assert html =~ "size-1.5"
  end

  test "integers over max (default 999) render as max+" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_badge content={1500}><span>bell</span></.pp_badge>")
    assert html =~ "999+"
    refute html =~ "1500"

    html = rendered_to_string(~H"<.pp_badge content={150} max={99}><span>bell</span></.pp_badge>")
    assert html =~ "99+"
  end

  test "string content is never truncated" do
    assigns = %{}
    assert rendered_to_string(~H"<.pp_badge content='NEW'><span>bell</span></.pp_badge>") =~ "NEW"
  end

  test "a count of 0, or invisible, hides the badge" do
    assigns = %{}

    refute rendered_to_string(~H"<.pp_badge content={0}><span>bell</span></.pp_badge>") =~
             "badge-dot"

    refute rendered_to_string(~H"<.pp_badge content={3} invisible><span>bell</span></.pp_badge>") =~
             "badge-dot"
  end

  test "paperize={false} drops the badge's classes but keeps the wrapper" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_badge content={2} paperize={false} class='mine'><span>bell</span></.pp_badge>"
      )

    refute html =~ "bg-pp-error"
    assert html =~ "mine"
    assert html =~ "relative inline-flex shrink-0"
  end
end
