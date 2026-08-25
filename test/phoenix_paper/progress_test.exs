defmodule PhoenixPaper.ProgressTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Progress

  test "linear (default), determinate: sets the bar width from value" do
    html = render_component(&linear_determinate/1)

    assert html =~ "width: 72%"
    assert html =~ ~s(aria-valuenow="72")
    refute html =~ "pp-progress-indeterminate"
  end

  defp linear_determinate(assigns) do
    ~H"""
    <.pp_progress value={72} />
    """
  end

  test "linear, indeterminate (no value): animates instead of a fixed width" do
    html = render_component(&linear_indeterminate/1)

    assert html =~ "pp-progress-indeterminate"
    refute html =~ "width: "
  end

  defp linear_indeterminate(assigns) do
    ~H"""
    <.pp_progress />
    """
  end

  test "circular, determinate: renders an svg arc sized by value" do
    html = render_component(&circular_determinate/1)

    assert html =~ "<svg"
    assert html =~ "stroke-dashoffset"
    assert html =~ ~s(aria-valuenow="50")
  end

  defp circular_determinate(assigns) do
    ~H"""
    <.pp_progress variant="circular" value={50} />
    """
  end

  test "circular, indeterminate: renders a spinning span, not an svg" do
    html = render_component(&circular_indeterminate/1)

    refute html =~ "<svg"
    assert html =~ "animate-spin"
  end

  defp circular_indeterminate(assigns) do
    ~H"""
    <.pp_progress variant="circular" />
    """
  end

  test "color picks the right literal class" do
    html = render_component(&secondary/1)
    assert html =~ "bg-pp-secondary"
  end

  defp secondary(assigns) do
    ~H"""
    <.pp_progress color="secondary" value={10} />
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-primary"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_progress paperize={false} class="my-class" value={10} />
    """
  end
end
