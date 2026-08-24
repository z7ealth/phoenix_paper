defmodule PhoenixPaper.ImageListTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ImageList

  test "defaults to a 3-column grid" do
    html = render_component(&default/1)
    assert html =~ "grid-cols-3"
  end

  defp default(assigns) do
    ~H"""
    <.pp_image_list>Content</.pp_image_list>
    """
  end

  test "cols overrides the column count" do
    html = render_component(&two_cols/1)
    assert html =~ "grid-cols-2"
    refute html =~ "grid-cols-3"
  end

  defp two_cols(assigns) do
    ~H"""
    <.pp_image_list cols={2}>Content</.pp_image_list>
    """
  end
end
