defmodule PhoenixPaper.TableBodyTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.TableBody

  test "renders a tbody with dividers scoped to its own direct child rows" do
    html = render_component(&body/1)

    assert html =~ "<tbody"
    assert html =~ "tr]:border-b"
    assert html =~ "content"
  end

  defp body(assigns) do
    ~H"""
    <.pp_table_body>content</.pp_table_body>
    """
  end

  test "striped adds alternating row backgrounds" do
    html = render_component(&striped/1)
    assert html =~ "nth-child(even)"
  end

  defp striped(assigns) do
    ~H"""
    <.pp_table_body striped>content</.pp_table_body>
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "border-b"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_table_body paperize={false} class="my-class">content</.pp_table_body>
    """
  end
end
