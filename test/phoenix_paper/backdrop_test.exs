defmodule PhoenixPaper.BackdropTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Backdrop

  test "open (default): renders the overlay with its content" do
    html = render_component(&backdrop/1)

    assert html =~ "fixed"
    assert html =~ "inset-0"
    assert html =~ "spinner"
  end

  defp backdrop(assigns) do
    ~H"""
    <.pp_backdrop>spinner</.pp_backdrop>
    """
  end

  test "open={false}: renders nothing at all" do
    html = render_component(&closed/1)
    assert String.trim(html) == ""
  end

  defp closed(assigns) do
    ~H"""
    <.pp_backdrop open={false}>spinner</.pp_backdrop>
    """
  end
end
