defmodule PhoenixPaper.ListItemTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ListItem

  test "renders as a link when href is given" do
    html = render_component(&linked/1)

    assert html =~ "<a"
    assert html =~ ~s(href="/settings")
    assert html =~ "Settings"
  end

  defp linked(assigns) do
    ~H"""
    <.pp_list_item href="/settings">Settings</.pp_list_item>
    """
  end

  test "renders as a plain div when no href/navigate/patch is given" do
    html = render_component(&static/1)

    refute html =~ "<a"
    assert html =~ ~s(role="listitem")
    assert html =~ "Info"
  end

  defp static(assigns) do
    ~H"""
    <.pp_list_item>Info</.pp_list_item>
    """
  end

  test "active renders the highlighted primary state, leading/secondary/trailing slots render" do
    html = render_component(&full/1)

    assert html =~ "bg-pp-primary/10"
    assert html =~ "text-pp-primary"
    assert html =~ "Icon"
    assert html =~ "Subtitle"
    assert html =~ "Badge"
  end

  defp full(assigns) do
    ~H"""
    <.pp_list_item href="/" active>
      <:leading>Icon</:leading>
      Title
      <:secondary>Subtitle</:secondary>
      <:trailing>Badge</:trailing>
    </.pp_list_item>
    """
  end

  test "disabled renders pointer-events-none and aria-disabled" do
    html = render_component(&disabled/1)

    assert html =~ "pointer-events-none"
    assert html =~ ~s(aria-disabled="true")
  end

  defp disabled(assigns) do
    ~H"""
    <.pp_list_item disabled>Locked</.pp_list_item>
    """
  end

  test "linked items ripple by default; ripple={false} drops the click handler" do
    html = render_component(&linked/1)
    assert html =~ "onclick="

    html = render_component(&no_ripple/1)
    refute html =~ "onclick="
  end

  defp no_ripple(assigns) do
    ~H"""
    <.pp_list_item href="/settings" ripple={false}>Settings</.pp_list_item>
    """
  end

  test "a static (non-link) item never ripples, even with ripple={true}" do
    html = render_component(&static_ripple/1)
    refute html =~ "onclick="
  end

  defp static_ripple(assigns) do
    ~H"""
    <.pp_list_item ripple={true}>Info</.pp_list_item>
    """
  end

  test "a linked item shows a pointer cursor; a static item doesn't (there's nothing to click)" do
    assert render_component(&linked/1) =~ "cursor-pointer"
    refute render_component(&static/1) =~ "cursor-pointer"
  end
end
