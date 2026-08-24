defmodule PhoenixPaper.SliderTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Slider

  test "renders a range input with the accent color and current value" do
    html = render_component(&slider/1)

    assert html =~ ~s(type="range")
    assert html =~ "accent-pp-secondary"
    assert html =~ ~s(value="40")
  end

  defp slider(assigns) do
    ~H"""
    <.pp_slider name="volume" label="Volume" value={40} color="secondary" />
    """
  end
end
