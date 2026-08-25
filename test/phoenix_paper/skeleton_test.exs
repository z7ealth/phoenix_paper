defmodule PhoenixPaper.SkeletonTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Skeleton

  test "variant=\"text\" (default): rounded, full width, ~1 line tall" do
    html = render_component(&text/1)

    assert html =~ "rounded"
    assert html =~ "width: 100%"
    assert html =~ "height: 1.2em"
    assert html =~ "animate-pulse"
  end

  defp text(assigns) do
    ~H"""
    <.pp_skeleton />
    """
  end

  test "variant=\"circular\" defaults to a 40px circle" do
    html = render_component(&circular/1)

    assert html =~ "rounded-full"
    assert html =~ "width: 40px"
    assert html =~ "height: 40px"
  end

  defp circular(assigns) do
    ~H"""
    <.pp_skeleton variant="circular" />
    """
  end

  test "explicit width/height override the variant's default, accepting bare integers as px" do
    html = render_component(&sized/1)

    assert html =~ "width: 200px"
    assert html =~ "height: 120px"
  end

  defp sized(assigns) do
    ~H"""
    <.pp_skeleton variant="rectangular" width={200} height={120} />
    """
  end

  test "animation=\"wave\" uses the shimmer utility instead of animate-pulse" do
    html = render_component(&wave/1)

    assert html =~ "pp-skeleton-wave"
    refute html =~ "animate-pulse"
  end

  defp wave(assigns) do
    ~H"""
    <.pp_skeleton animation="wave" />
    """
  end

  test "animation=\"none\" has neither animation class" do
    html = render_component(&none/1)

    refute html =~ "animate-pulse"
    refute html =~ "pp-skeleton-wave"
  end

  defp none(assigns) do
    ~H"""
    <.pp_skeleton animation="none" />
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-on-surface"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_skeleton paperize={false} class="my-class" />
    """
  end
end
