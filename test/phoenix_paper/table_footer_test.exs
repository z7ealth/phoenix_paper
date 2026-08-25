defmodule PhoenixPaper.TableFooterTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.TableFooter

  test "renders a tfoot with a top border on descendant td cells" do
    html = render_component(&footer/1)

    assert html =~ "<tfoot"
    assert html =~ "td]:border-t-2"
    assert html =~ "content"
  end

  defp footer(assigns) do
    ~H"""
    <.pp_table_footer>content</.pp_table_footer>
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "border-t-2"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_table_footer paperize={false} class="my-class">content</.pp_table_footer>
    """
  end
end
