defmodule PhoenixPaper.BadgeTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Badge

  test "renders content and the default error color" do
    html = render_component(&with_content/1)

    assert html =~ "4"
    assert html =~ "bg-pp-error"
    assert html =~ "text-pp-on-error"
  end

  defp with_content(assigns) do
    ~H"""
    <.pp_badge content={4}>
      <span>bell</span>
    </.pp_badge>
    """
  end

  test "content over max renders as max+" do
    html = render_component(&over_max/1)

    assert html =~ "99+"
    refute html =~ "150"
  end

  defp over_max(assigns) do
    ~H"""
    <.pp_badge content={150}>
      <span>bell</span>
    </.pp_badge>
    """
  end

  test "string content is never truncated by max" do
    html = render_component(&string_content/1)
    assert html =~ "NEW"
  end

  defp string_content(assigns) do
    ~H"""
    <.pp_badge content="NEW">
      <span>bell</span>
    </.pp_badge>
    """
  end

  test "content nil with variant=standard (default) hides the badge" do
    html = render_component(&no_content/1)
    refute html =~ "badge-dot"
  end

  defp no_content(assigns) do
    ~H"""
    <.pp_badge>
      <span>bell</span>
    </.pp_badge>
    """
  end

  test "variant=dot with no content still shows a blank dot" do
    html = render_component(&dot/1)

    assert html =~ "badge-dot"
    assert html =~ "size-1.5"
  end

  defp dot(assigns) do
    ~H"""
    <.pp_badge variant="dot" color="success">
      <span>online</span>
    </.pp_badge>
    """
  end

  test "content 0 hides the badge unless show_zero is set" do
    html = render_component(&zero/1)
    refute html =~ "badge-dot"

    html = render_component(&zero_shown/1)
    assert html =~ "badge-dot"
  end

  defp zero(assigns) do
    ~H"""
    <.pp_badge content={0}>
      <span>bell</span>
    </.pp_badge>
    """
  end

  defp zero_shown(assigns) do
    ~H"""
    <.pp_badge content={0} show_zero>
      <span>bell</span>
    </.pp_badge>
    """
  end

  test "invisible forces the badge to hide regardless of content" do
    html = render_component(&invisible/1)
    refute html =~ "badge-dot"
  end

  defp invisible(assigns) do
    ~H"""
    <.pp_badge content={4} invisible>
      <span>bell</span>
    </.pp_badge>
    """
  end

  test "overlap=circular pulls the badge inward instead of sitting flush on the corner" do
    html = render_component(&circular/1)
    assert html =~ "top-[14%]"
    refute html =~ "top-0 right-0"
  end

  defp circular(assigns) do
    ~H"""
    <.pp_badge content={1} overlap="circular">
      <span>avatar</span>
    </.pp_badge>
    """
  end

  test "anchor_origin picks the corner" do
    html = render_component(&bottom_left/1)
    assert html =~ "bottom-0"
    assert html =~ "left-0"
  end

  defp bottom_left(assigns) do
    ~H"""
    <.pp_badge content={1} anchor_origin="bottom-left">
      <span>avatar</span>
    </.pp_badge>
    """
  end

  test "paperize={false}: no built-in classes on the badge dot, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-error"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_badge content={4} paperize={false} class="my-class">
      <span>bell</span>
    </.pp_badge>
    """
  end
end
