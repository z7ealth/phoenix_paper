defmodule PhoenixPaper.BoxTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Box

  test "renders a plain div by default with only the caller's class" do
    html = render_component(&div_box/1)

    assert html =~ "<div"
    assert html =~ "my-class"
    assert html =~ "Content"
  end

  defp div_box(assigns) do
    ~H"""
    <.pp_box class="my-class">Content</.pp_box>
    """
  end

  test "tag=\"span\" renders a span instead" do
    html = render_component(&span_box/1)

    assert html =~ "<span"
    refute html =~ "<div"
  end

  defp span_box(assigns) do
    ~H"""
    <.pp_box tag="span">Content</.pp_box>
    """
  end

  test "tag=\"pre\" renders a pre instead" do
    html = render_component(&pre_box/1)

    assert html =~ "<pre"
    refute html =~ "<div"
  end

  defp pre_box(assigns) do
    ~H"""
    <.pp_box tag="pre">Content</.pp_box>
    """
  end
end
