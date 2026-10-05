defmodule PhoenixPaper.IconTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Icon

  test "renders the heroicon class at the default md size" do
    html = render_component(&default/1)

    assert html =~ "hero-check"
    assert html =~ "inline-block"
    assert html =~ "size-6"
  end

  defp default(assigns) do
    ~H"""
    <.pp_icon name="hero-check" />
    """
  end

  test "size picks exactly one size class" do
    html = render_component(&small/1)

    assert html =~ "size-5"
    refute html =~ "size-6"
  end

  defp small(assigns) do
    ~H"""
    <.pp_icon name="hero-check" size="sm" />
    """
  end

  test "size=none emits no built-in size, so the caller's class is the only one" do
    html = render_component(&custom/1)

    assert html =~ "size-10"
    refute html =~ "size-5"
  end

  defp custom(assigns) do
    ~H"""
    <.pp_icon name="hero-check" size="none" class="size-10" />
    """
  end

  test "paperize=false keeps only the icon name and caller class" do
    html = render_component(&bare/1)

    assert html =~ "hero-check"
    assert html =~ "my-icon"
    refute html =~ "inline-block"
    refute html =~ "size-5"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_icon name="hero-check" paperize={false} class="my-icon" />
    """
  end
end
