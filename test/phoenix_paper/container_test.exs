defmodule PhoenixPaper.ContainerTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Container

  test "defaults to max-w-screen-lg and centers with mx-auto" do
    html = render_component(&default/1)

    assert html =~ "max-w-screen-lg"
    assert html =~ "mx-auto"
  end

  defp default(assigns) do
    ~H"""
    <.pp_container>Content</.pp_container>
    """
  end

  test "max_width overrides the breakpoint" do
    html = render_component(&sm/1)
    assert html =~ "max-w-screen-sm"
  end

  defp sm(assigns) do
    ~H"""
    <.pp_container max_width="sm">Content</.pp_container>
    """
  end

  test "paperize={false} drops built-in classes" do
    html = render_component(&bare/1)
    refute html =~ "mx-auto"
    assert html =~ "my-container"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_container paperize={false} class="my-container">Content</.pp_container>
    """
  end
end
