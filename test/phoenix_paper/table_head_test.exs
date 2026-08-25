defmodule PhoenixPaper.TableHeadTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.TableHead

  test "renders a thead with a border on descendant th cells" do
    html = render_component(&head/1)

    assert html =~ "<thead"
    assert html =~ "th]:border-b-2"
    assert html =~ "content"
  end

  defp head(assigns) do
    ~H"""
    <.pp_table_head>content</.pp_table_head>
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "border-b-2"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_table_head paperize={false} class="my-class">content</.pp_table_head>
    """
  end
end
