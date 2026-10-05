defmodule PhoenixPaper.ProgressTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Progress

  test "linear determinate: indicator, gap, secondary-container track, stop indicator" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_progress value={40} label='Upload' />")

    assert html =~ ~s(role="progressbar")
    assert html =~ ~s(aria-valuenow="40")
    assert html =~ ~s(aria-label="Upload")
    assert html =~ "gap-1"
    assert html =~ "flex: 0 1 40%"
    assert html =~ "bg-pp-secondary-container"
    assert html =~ "size-1"
  end

  test "stop_indicator={false} and value 100 drop the track/dot" do
    assigns = %{}

    no_stop = rendered_to_string(~H"<.pp_progress value={40} stop_indicator={false} />")
    full = rendered_to_string(~H"<.pp_progress value={100} />")

    refute no_stop =~ "end-0 top-1/2 size-1"
    refute full =~ "bg-pp-secondary-container"
  end

  test "linear indeterminate: two segments over the track" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_progress />")

    refute html =~ "aria-valuenow"
    assert html =~ "pp-progress-indeterminate-1"
    assert html =~ "pp-progress-indeterminate-2"
  end

  test "wavy (Expressive) masks the indicator with the wave tile; thickness 8" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_progress value={50} wavy />
      <.pp_progress wavy thickness={8} />
      """)

    assert html =~ "pp-progress-wave "
    assert html =~ "pp-progress-wave-mask-thick"
    assert html =~ "pp-progress-wave-indeterminate-1"
  end

  test "circular determinate: SVG arc with a gapped track" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_progress variant='circular' value={25} />")

    assert html =~ "<svg"
    assert html =~ ~s(viewBox="0 0 48 48")
    assert html =~ "stroke-pp-secondary-container"
    assert html =~ "stroke-dasharray"
    assert html =~ "stroke-dashoffset"
  end

  test "circular indeterminate rotates; wavy uses the precomputed path" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_progress variant="circular" />
      <.pp_progress variant="circular" wavy value={60} />
      """)

    assert html =~ "pp-circular-rotate"
    assert html =~ "pp-circular-dash"
    assert html =~ ~s(pathLength="100")
    assert html =~ ~s(stroke-dasharray="60 100")
  end

  test "color picks the indicator role" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_progress value={10} color='tertiary' />")
    assert html =~ "bg-pp-tertiary"
  end

  test "paperize={false}: no built-in classes" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_progress value={10} paperize={false} class='mine' />")
    refute html =~ "bg-pp-primary"
    assert html =~ "mine"
  end
end
