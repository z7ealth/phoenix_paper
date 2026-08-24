defmodule PhoenixPaper.ImageListItemTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ImageListItem

  test "renders the image and, when given, the title/subtitle overlay bar" do
    html = render_component(&with_bar/1)

    assert html =~ ~s(src="/img.jpg")
    assert html =~ "Breakfast"
    assert html =~ "Café"
  end

  defp with_bar(assigns) do
    ~H"""
    <.pp_image_list_item src="/img.jpg" title="Breakfast" subtitle="Café" />
    """
  end

  test "no title means no overlay bar at all" do
    html = render_component(&no_bar/1)
    refute html =~ "bg-gradient-to-t"
  end

  defp no_bar(assigns) do
    ~H"""
    <.pp_image_list_item src="/img.jpg" />
    """
  end
end
