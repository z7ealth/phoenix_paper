defmodule PhoenixPaper.TableContainerTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.TableContainer

  test "paperize (default): an outlined MD3 card surface with horizontal scroll" do
    html = render_component(&container/1)

    assert html =~ "overflow-x-auto"
    assert html =~ "bg-pp-surface"
    assert html =~ "border-pp-outline-variant"
    assert html =~ "rounded-pp-md"
    assert html =~ ~s(data-pp-component="table-container")
    assert html =~ "content"
  end

  defp container(assigns) do
    ~H"""
    <.pp_table_container>content</.pp_table_container>
    """
  end

  test "paperize={false}: no built-in classes at all, not even overflow-x-auto" do
    html = render_component(&bare/1)

    refute html =~ "overflow-x-auto"
    refute html =~ "bg-pp-surface"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_table_container paperize={false} class="my-class">content</.pp_table_container>
    """
  end

  test "variant picks the card surface" do
    assigns = %{}

    assert rendered_to_string(~H"<.pp_table_container variant='filled'>x</.pp_table_container>") =~
             "bg-pp-surface-container-highest"

    assert rendered_to_string(~H"<.pp_table_container variant='elevated'>x</.pp_table_container>") =~
             "pp-elevation-1"
  end
end
