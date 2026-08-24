defmodule PhoenixPaper.RatingTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Rating

  test "interactive rating renders one flat radio+label pair per star" do
    html = render_component(&interactive/1)

    assert Regex.scan(~r/type="radio"/, html) |> length() == 5
    assert html =~ ~s(id="stars-star-3")
    assert html =~ ~s(for="stars-star-3")
  end

  defp interactive(assigns) do
    ~H"""
    <.pp_rating id="stars" name="stars" value={3} />
    """
  end

  test "readonly renders plain filled/unfilled spans, no inputs" do
    html = render_component(&readonly/1)

    refute html =~ "type=\"radio\""
    assert Regex.scan(~r/text-pp-secondary/, html) |> length() == 3
  end

  defp readonly(assigns) do
    ~H"""
    <.pp_rating readonly value={3} />
    """
  end
end
