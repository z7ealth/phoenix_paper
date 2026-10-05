defmodule PhoenixPaper.LoadingIndicatorTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.LoadingIndicator

  test "a rotating SVG whose path morphs, sized in px" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_loading_indicator label='Loading mail' size={36} />")

    assert html =~ ~s(role="progressbar")
    assert html =~ ~s(aria-label="Loading mail")
    assert html =~ "pp-loading-rotate"
    assert html =~ "pp-loading-morph"
    assert html =~ ~s(d="M24.00 5.00)
    assert html =~ "width: 36px; height: 36px"
    assert html =~ "text-pp-primary"
  end

  test "contained sits on a primary-container circle" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_loading_indicator contained />")
    assert html =~ "bg-pp-primary-container text-pp-on-primary-container"
  end
end
