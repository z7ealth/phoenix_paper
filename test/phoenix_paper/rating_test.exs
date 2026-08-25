defmodule PhoenixPaper.RatingTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Rating

  test "field= populates name/value from the form field" do
    html = render_component(&with_field/1)

    assert html =~ ~s(name="user[stars]")
    assert html =~ ~s(id="user_stars-star-3")
  end

  defp with_field(assigns) do
    form = Phoenix.Component.to_form(%{"stars" => "3"}, as: :user)

    assigns = assign(assigns, :form, form)

    ~H"""
    <.pp_rating field={@form[:stars]} />
    """
  end

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
