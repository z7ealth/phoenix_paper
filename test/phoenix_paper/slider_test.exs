defmodule PhoenixPaper.SliderTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Slider

  test "field= populates name/id/value from the form field" do
    html = render_component(&with_field/1)

    assert html =~ ~s(id="user_volume")
    assert html =~ ~s(name="user[volume]")
    assert html =~ ~s(value="70")
  end

  defp with_field(assigns) do
    form = Phoenix.Component.to_form(%{"volume" => "70"}, as: :user)

    assigns = assign(assigns, :form, form)

    ~H"""
    <.pp_slider field={@form[:volume]} />
    """
  end

  test "renders a range input with the color utility and current value" do
    html = render_component(&slider/1)

    assert html =~ ~s(type="range")
    assert html =~ "pp-slider-secondary"
    assert html =~ ~s(value="40")
    assert html =~ "Volume"
  end

  defp slider(assigns) do
    ~H"""
    <.pp_slider name="volume" label="Volume" value={40} color="secondary" />
    """
  end

  test "no value defaults to the midpoint of min/max" do
    html = render_component(&no_value/1)
    assert html =~ ~s(value="50")
  end

  defp no_value(assigns) do
    ~H"""
    <.pp_slider name="volume" />
    """
  end

  test "sets --pp-slider-percent inline for the initial paint and wires the live-sync oninput" do
    html = render_component(&slider/1)

    assert html =~ "--pp-slider-percent: 40.0%"
    assert html =~ "oninput="
  end

  test "size=\"small\" uses the small shape utility" do
    html = render_component(&small/1)
    assert html =~ "pp-slider-small"
  end

  defp small(assigns) do
    ~H"""
    <.pp_slider name="volume" size="small" />
    """
  end

  test "orientation=\"vertical\" uses the vertical shape utility" do
    html = render_component(&vertical/1)
    assert html =~ "pp-slider-vertical"
  end

  defp vertical(assigns) do
    ~H"""
    <.pp_slider name="volume" orientation="vertical" />
    """
  end

  test "track=\"none\"/\"inverted\" render the matching track utility, \"normal\" renders neither" do
    assert render_component(&track_none/1) =~ "pp-slider-track-none"
    assert render_component(&track_inverted/1) =~ "pp-slider-track-inverted"
    refute render_component(&slider/1) =~ "pp-slider-track"
  end

  defp track_none(assigns) do
    ~H"""
    <.pp_slider name="volume" track="none" />
    """
  end

  defp track_inverted(assigns) do
    ~H"""
    <.pp_slider name="volume" track="inverted" />
    """
  end

  test "marks={true} renders a datalist with an option at every step" do
    html = render_component(&marks_true/1)

    assert html =~ "<datalist"
    assert html =~ ~s(value="0.0")
    assert html =~ ~s(value="50.0")
    assert html =~ ~s(value="100.0")
  end

  defp marks_true(assigns) do
    ~H"""
    <.pp_slider name="volume" marks={true} step={50} />
    """
  end

  test "marks with a list of {value, label} tuples renders labels positioned by percent" do
    html = render_component(&marks_labeled/1)

    assert html =~ "0°C"
    assert html =~ "100°C"
    assert html =~ "left: 0.0%"
    assert html =~ "left: 100.0%"
  end

  defp marks_labeled(assigns) do
    ~H"""
    <.pp_slider name="temp" marks={[{0, "0°C"}, {100, "100°C"}]} />
    """
  end

  test "range slider (a {low, high} tuple value) renders two inputs named _min/_max" do
    html = render_component(&range/1)

    assert html =~ ~s(name="price_min")
    assert html =~ ~s(name="price_max")
    assert html =~ ~s(value="20")
    assert html =~ ~s(value="80")
    assert html =~ "20 – 80"
    assert html =~ "pp-slider-range-input"
  end

  defp range(assigns) do
    ~H"""
    <.pp_slider name="price" label="Price" value={{20, 80}} />
    """
  end

  test "disabled renders the disabled attribute" do
    html = render_component(&disabled/1)
    assert html =~ "disabled"
  end

  defp disabled(assigns) do
    ~H"""
    <.pp_slider name="volume" disabled />
    """
  end

  test "paperize={false} drops the shape/color utilities but keeps the input functional" do
    html = render_component(&bare/1)

    refute html =~ "pp-slider-primary"
    assert html =~ ~s(type="range")
    assert html =~ "my-slider"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_slider name="volume" paperize={false} class="my-slider" />
    """
  end
end
