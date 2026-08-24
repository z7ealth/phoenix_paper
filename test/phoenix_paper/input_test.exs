defmodule PhoenixPaper.InputTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Input

  test "renders the floating label and outlined classes by default" do
    html = render_component(&outlined/1)

    assert html =~ "border-pp-outline"
    assert html =~ "peer-focus:text-xs"
    assert html =~ "Email"
    assert html =~ ~s(placeholder=" ")
  end

  defp outlined(assigns) do
    ~H"""
    <.pp_input label="Email" name="email" />
    """
  end

  test "filled variant only rounds the top corners" do
    html = render_component(&filled/1)
    assert html =~ ~r/\brounded-t\b/
    assert html =~ "bg-pp-surface-variant"
  end

  defp filled(assigns) do
    ~H"""
    <.pp_input variant="filled" label="Name" name="name" />
    """
  end

  test "renders error messages and error classes instead of helper text" do
    html = render_component(&with_errors/1)

    assert html =~ "border-pp-error"
    assert html =~ "can&#39;t be blank"
    refute html =~ "Must be at least 3 characters"
  end

  defp with_errors(assigns) do
    ~H"""
    <.pp_input label="Name" name="name" errors={["can't be blank"]} helper_text="Must be at least 3 characters" />
    """
  end

  test "paperize={false} renders a bare input with no built-in classes" do
    html = render_component(&bare/1)

    refute html =~ "border-pp-outline"
    refute html =~ "peer-focus"
    assert html =~ "my-input"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_input paperize={false} label="Email" name="email" class="my-input" />
    """
  end
end
