defmodule PhoenixPaper.TooltipTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Tooltip

  test "renders the title in a hidden-until-hover bubble" do
    html = render_component(&basic/1)

    assert html =~ "Delete"
    assert html =~ "opacity-0"
    assert html =~ "group-hover:opacity-100"
    assert html =~ "group-focus-within:opacity-100"
  end

  defp basic(assigns) do
    ~H"""
    <.pp_tooltip title="Delete">
      <button>x</button>
    </.pp_tooltip>
    """
  end

  test "title=nil renders only the trigger, no tooltip bubble" do
    html = render_component(&no_title/1)

    refute html =~ "tooltip-bubble"
    assert html =~ "trigger"
  end

  defp no_title(assigns) do
    ~H"""
    <.pp_tooltip>
      <span>trigger</span>
    </.pp_tooltip>
    """
  end

  test "title=\"\" also disables the tooltip, matching MUI" do
    html = render_component(&empty_title/1)
    refute html =~ "tooltip-bubble"
  end

  defp empty_title(assigns) do
    ~H"""
    <.pp_tooltip title="">
      <span>trigger</span>
    </.pp_tooltip>
    """
  end

  test "placement picks the position classes" do
    html = render_component(&right_placement/1)
    assert html =~ "left-full"
  end

  defp right_placement(assigns) do
    ~H"""
    <.pp_tooltip title="Info" placement="right">
      <span>trigger</span>
    </.pp_tooltip>
    """
  end

  test "arrow renders an extra rotated square" do
    html = render_component(&with_arrow/1)
    assert html =~ "rotate-45"
  end

  defp with_arrow(assigns) do
    ~H"""
    <.pp_tooltip title="Info" arrow>
      <span>trigger</span>
    </.pp_tooltip>
    """
  end

  test "arrow={false} (default) renders no rotated square" do
    html = render_component(&basic/1)
    refute html =~ "rotate-45"
  end

  test "paperize={false}: no built-in classes on the bubble, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-on-surface"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_tooltip title="Info" paperize={false} class="my-class">
      <span>trigger</span>
    </.pp_tooltip>
    """
  end

  describe "colors and styles" do
    test "defaults to the raised inverted chip, unchanged" do
      html = render_component(&basic/1)
      assert html =~ "bg-pp-on-surface text-pp-surface"
      assert html =~ "shadow-md"
      assert html =~ "px-2 py-1 text-xs"
      assert html =~ ~s( rounded")
    end

    test "color fills the bubble and the arrow with a brand color pair" do
      for color <- ~w(primary secondary accent error) do
        assigns = %{color: color}

        html =
          rendered_to_string(~H"""
          <.pp_tooltip title="t" color={@color} arrow><button>x</button></.pp_tooltip>
          """)

        assert html =~ "bg-pp-#{color} text-pp-on-#{color}"
        assert html =~ ~r/rotate-45 bg-pp-#{color}/
      end
    end

    test "flat drops the shadow" do
      assigns = %{}
      html = rendered_to_string(~H"<.pp_tooltip title='t' variant='flat'><b>x</b></.pp_tooltip>")
      refute html =~ "shadow-md"
      assert html =~ "bg-pp-on-surface"
    end

    test "outlined is a bordered surface, arrow bordered on its outer edges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_tooltip title="t" variant="outlined" color="error" arrow><b>x</b></.pp_tooltip>
        """)

      assert html =~ "border border-pp-error bg-pp-surface text-pp-error"
      assert html =~ "bg-pp-surface border-pp-error border-b border-r"
      refute html =~ "shadow-md"
    end

    test "outlined arrow edges follow the placement" do
      for {placement, edges} <- [
            {"top", "border-b border-r"},
            {"bottom", "border-t border-l"},
            {"left", "border-t border-r"},
            {"right", "border-b border-l"}
          ] do
        assigns = %{placement: placement}

        html =
          rendered_to_string(~H"""
          <.pp_tooltip title="t" variant="outlined" placement={@placement} arrow><b>x</b></.pp_tooltip>
          """)

        assert html =~ edges
      end
    end

    test "size and shape" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pp_tooltip title="t" size="large" shape={:full}><b>x</b></.pp_tooltip>
        """)

      assert html =~ "px-3 py-1.5 text-sm"
      assert html =~ "rounded-full"
    end
  end
end
