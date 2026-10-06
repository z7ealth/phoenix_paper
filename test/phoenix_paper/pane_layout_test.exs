defmodule PhoenixPaper.PaneLayoutTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.PaneLayout

  defp pane(html, name) do
    [tag] = Regex.run(~r/<div[^>]*data-pp-pane="#{name}"[^>]*>/, html)
    tag
  end

  describe "pp_list_detail" do
    test "MD3 margins (16dp, 24dp from 600dp) and the 24dp spacer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_list_detail><:list>L</:list><:detail>D</:detail></.pp_list_detail>
        """)

      assert html =~ "gap-6 px-4 min-[600px]:px-6"
    end

    test "compact/medium show the list by default; expanded shows both, the list at 360dp" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_list_detail><:list>L</:list><:detail>D</:detail></.pp_list_detail>
        """)

      assert pane(html, "list") =~ "flex w-full"
      assert pane(html, "list") =~ "min-[840px]:w-[360px]"
      assert pane(html, "detail") =~ "hidden min-[840px]:flex"
      assert pane(html, "detail") =~ "flex-1"
    end

    test "show_detail swaps which pane compact/medium windows show" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_list_detail show_detail><:list>L</:list><:detail>D</:detail></.pp_list_detail>
        """)

      assert html =~ ~s(data-pp-show-detail="true")
      assert pane(html, "list") =~ "hidden min-[840px]:flex"
      refute pane(html, "detail") =~ "hidden"
    end

    test "paperize false keeps pane visibility, drops margins and widths" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_list_detail paperize={false} class="mine"><:list>L</:list><:detail>D</:detail></.pp_list_detail>
        """)

      assert html =~ "mine"
      refute html =~ "px-4"
      refute html =~ "w-[360px]"
      assert pane(html, "detail") =~ "hidden min-[840px]:flex"
    end
  end

  describe "pp_supporting_pane" do
    test "stacks below 840dp, sits beside the main pane at 360dp from 840dp" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_supporting_pane>Main<:supporting>Side</:supporting></.pp_supporting_pane>
        """)

      assert html =~ "flex flex-col min-[840px]:flex-row"
      assert html =~ "gap-6 px-4 min-[600px]:px-6"
      assert pane(html, "main") =~ "flex-1"
      assert pane(html, "supporting") =~ "min-[840px]:w-[360px]"
      assert html =~ "Main"
      assert html =~ "Side"
    end
  end
end
