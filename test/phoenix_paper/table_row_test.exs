defmodule PhoenixPaper.TableRowTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.TableRow

  test "renders a tr with a hover highlight by default" do
    html = render_component(&row/1)

    assert html =~ "<tr"
    assert html =~ "hover:bg-pp-on-surface/5"
    assert html =~ "content"
  end

  defp row(assigns) do
    ~H"""
    <.pp_table_row>content</.pp_table_row>
    """
  end

  test "selected renders a stronger, persistent highlight instead" do
    html = render_component(&selected/1)

    assert html =~ "bg-pp-primary/10"
    refute html =~ "hover:bg-pp-on-surface/5"
  end

  defp selected(assigns) do
    ~H"""
    <.pp_table_row selected>content</.pp_table_row>
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "hover:bg-pp-on-surface/5"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_table_row paperize={false} class="my-class">content</.pp_table_row>
    """
  end
end
