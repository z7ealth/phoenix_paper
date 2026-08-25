defmodule PhoenixPaper.AlertTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Alert

  test "severity (default: info) picks the color and icon" do
    html = render_component(&info/1)

    assert html =~ "bg-pp-info/10"
    assert html =~ "hero-information-circle"
    assert html =~ "Heads up"
  end

  defp info(assigns) do
    ~H"""
    <.pp_alert>Heads up</.pp_alert>
    """
  end

  test "severity=\"error\" uses the error color and icon" do
    html = render_component(&error/1)

    assert html =~ "bg-pp-error/10"
    assert html =~ "hero-x-circle"
  end

  defp error(assigns) do
    ~H"""
    <.pp_alert severity="error">Something broke</.pp_alert>
    """
  end

  test "variant=\"filled\" uses a solid background instead of a tint" do
    html = render_component(&filled/1)

    assert html =~ "bg-pp-success"
    assert html =~ "text-pp-on-success"
    refute html =~ "bg-pp-success/10"
  end

  defp filled(assigns) do
    ~H"""
    <.pp_alert severity="success" variant="filled">Saved</.pp_alert>
    """
  end

  test "title and action slots render when given" do
    html = render_component(&with_slots/1)

    assert html =~ "Heads up"
    assert html =~ "Retry"
  end

  defp with_slots(assigns) do
    ~H"""
    <.pp_alert severity="warning">
      <:title>Heads up</:title>
      Something needs attention.
      <:action>Retry</:action>
    </.pp_alert>
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-info"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_alert paperize={false} class="my-class">Heads up</.pp_alert>
    """
  end
end
