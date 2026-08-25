defmodule PhoenixPaper.ChipTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Chip

  test "renders as a <div> by default, with the default neutral color" do
    html = render_component(&basic/1)

    assert html =~ "<div"
    refute html =~ "<button"
    assert html =~ "bg-pp-surface-variant"
    assert html =~ "Basic"
  end

  defp basic(assigns) do
    ~H"""
    <.pp_chip>Basic</.pp_chip>
    """
  end

  test "variant=outlined uses a border instead of a filled background" do
    html = render_component(&outlined/1)

    assert html =~ "border-pp-primary"
    assert html =~ "bg-transparent"
  end

  defp outlined(assigns) do
    ~H"""
    <.pp_chip variant="outlined" color="primary">Outlined</.pp_chip>
    """
  end

  test "size=small uses the smaller height scale" do
    html = render_component(&small/1)
    assert html =~ "h-6"
  end

  defp small(assigns) do
    ~H"""
    <.pp_chip size="small">Small</.pp_chip>
    """
  end

  test "clickable renders a real <button> with a ripple onclick" do
    html = render_component(&clickable/1)

    assert html =~ "<button"
    refute html =~ "<div"
    assert html =~ "onclick="
  end

  defp clickable(assigns) do
    ~H"""
    <.pp_chip clickable>Filter</.pp_chip>
    """
  end

  test "clickable={false} (default) renders no onclick ripple" do
    html = render_component(&basic/1)
    refute html =~ "onclick="
  end

  test "icon slot renders leading content" do
    html = render_component(&with_icon/1)
    assert html =~ "hero-check"
  end

  defp with_icon(assigns) do
    ~H"""
    <.pp_chip>
      Tagged
      <:icon><span class="hero-check" /></:icon>
    </.pp_chip>
    """
  end

  test "deletable renders a delete control wired to on_delete, and it isn't a nested <button>" do
    html = render_component(&deletable/1)

    assert html =~ "chip-delete"
    assert html =~ ~s(role="button")
    assert html =~ "remove_tag"

    # No event.stopPropagation() here -- LiveView's phx-click binding is one
    # delegated window-level listener bound during the bubble phase, so
    # stopPropagation() on this element would prevent the click from ever
    # reaching it and on_delete would silently never fire (confirmed with a
    # real click in a real browser). It's also unnecessary: LiveView already
    # resolves a click to the nearest phx-click-bearing ancestor-or-self via
    # closestPhxBinding, so a click here never falls through to a
    # `clickable` chip's own phx-click on the outer <button>.
    refute html =~ "stopPropagation"
  end

  defp deletable(assigns) do
    ~H"""
    <.pp_chip deletable on_delete={Phoenix.LiveView.JS.push("remove_tag")}>
      React
    </.pp_chip>
    """
  end

  test "deletable={false} (default) renders no delete control" do
    html = render_component(&basic/1)
    refute html =~ "chip-delete"
  end

  test "disabled dims the chip and, when clickable, disables the real button" do
    html = render_component(&disabled_clickable/1)

    assert html =~ "opacity-40"
    assert html =~ "disabled"
  end

  defp disabled_clickable(assigns) do
    ~H"""
    <.pp_chip clickable disabled>Filter</.pp_chip>
    """
  end

  test "disabled also removes the delete control from the tab order" do
    html = render_component(&disabled_deletable/1)
    assert html =~ ~s(tabindex="-1")
  end

  defp disabled_deletable(assigns) do
    ~H"""
    <.pp_chip deletable disabled on_delete={Phoenix.LiveView.JS.push("remove_tag")}>
      React
    </.pp_chip>
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-surface-variant"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_chip paperize={false} class="my-class">Bare</.pp_chip>
    """
  end
end
