defmodule PhoenixPaper.SliderTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Slider

  test "field= populates name/id/value from the form field" do
    form = Phoenix.Component.to_form(%{"volume" => "30"}, as: :settings)
    assigns = %{form: form}
    html = rendered_to_string(~H"<.pp_slider field={@form[:volume]} />")

    assert html =~ ~s(id="settings_volume")
    assert html =~ ~s(name="settings[volume]")
    assert html =~ ~s(value="30")
  end

  test "renders a range input over a separately painted MD3 track" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_slider name='v' value={60} label='Volume' />")

    assert html =~ ~s(type="range")
    assert html =~ "pp-slider-input"
    assert html =~ "pp-slider-track-shape pp-slider-track-normal"
    assert html =~ "--pp-slider-f: 0.6"
    assert html =~ "[--pp-slider-active:var(--color-pp-primary)]"
    assert html =~ "[--pp-slider-inactive:var(--color-pp-secondary-container)]"
    assert html =~ "[--pp-slider-track-size:16px]"
    assert html =~ "Volume"
    assert html =~ "data-pp-slider-current"
    assert html =~ "oninput="
  end

  test "no value defaults to the midpoint" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_slider name='v' min={0} max={10} />")
    assert html =~ ~s(value="5")
  end

  test "Expressive sizes set the track/handle vars" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_slider name='v' size='xl' />")
    assert html =~ "[--pp-slider-track-size:96px]"
    assert html =~ "[--pp-slider-handle:108px]"
  end

  test "track modes, stop indicator toggle and color" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_slider name="a" track="centered" />
      <.pp_slider name="b" track="inverted" color="tertiary" />
      <.pp_slider name="c" track="none" stop_indicator={false} />
      """)

    assert html =~ "pp-slider-track-centered"
    assert html =~ "pp-slider-track-inverted"
    assert html =~ "pp-slider-track-none"
    assert html =~ "pp-slider-no-stop"
    assert html =~ "[--pp-slider-active:var(--color-pp-tertiary)]"
  end

  test "value_indicator renders the bubble positioned off --pp-slider-f" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_slider name='v' value={20} value_indicator />")

    assert html =~ "data-pp-slider-value"
    assert html =~ "bg-pp-inverse-surface"
    assert html =~ "left-[calc(2px+(100%-4px)*var(--pp-slider-f))]"
  end

  test "marks render a datalist, stop dots and labels" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_slider name="t" min={0} max={100} marks={[{0, "0°"}, {100, "100°"}]} />
      """)

    assert html =~ "<datalist"
    assert html =~ ~s(<option value="0">)
    assert html =~ "100°"
    assert html =~ "left: calc(2px + (100% - 4px) * 1.0)"
  end

  test "range slider: two inputs named _min/_max and range track vars" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_slider name='price' value={{20, 80}} label='Price' />")

    assert html =~ ~s(name="price_min")
    assert html =~ ~s(name="price_max")
    assert html =~ "pp-slider-track-range"
    assert html =~ "--pp-slider-lo: 0.2; --pp-slider-hi: 0.8"
    assert html =~ "pp-slider-input-range"
    assert html =~ "20 – 80"
  end

  test "vertical uses the vertical utilities" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_slider name='v' orientation='vertical' />")
    assert html =~ "pp-slider-input-vertical"
    assert html =~ "pp-slider-track-vertical"
  end

  test "disabled" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_slider name='v' disabled />")
    assert html =~ "disabled"
  end

  test "paperize={false} drops the track and utilities but keeps the input" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_slider name='v' paperize={false} class='mine' />")

    assert html =~ ~s(type="range")
    refute html =~ "pp-slider-track"
    refute html =~ "pp-slider-input"
    assert html =~ "mine"
  end
end
