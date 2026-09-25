defmodule PhoenixPaper.ToggleButtonTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ToggleButton

  test "pressed renders the filled state and aria-pressed=true" do
    html = render_component(&pressed/1)

    assert html =~ "bg-pp-primary"
    assert html =~ ~s(aria-pressed="true")
  end

  defp pressed(assigns) do
    ~H"""
    <.pp_toggle_button pressed={true}>Bold</.pp_toggle_button>
    """
  end

  test "unpressed renders the outline state and aria-pressed=false" do
    html = render_component(&unpressed/1)

    refute html =~ "border-pp-primary bg-pp-primary"
    assert html =~ "border-pp-outline"
    assert html =~ ~s(aria-pressed="false")
  end

  defp unpressed(assigns) do
    ~H"""
    <.pp_toggle_button>Bold</.pp_toggle_button>
    """
  end

  test "ripple={false} drops the click handler" do
    html = render_component(&no_ripple/1)
    refute html =~ "onclick="
  end

  defp no_ripple(assigns) do
    ~H"""
    <.pp_toggle_button ripple={false}>Bold</.pp_toggle_button>
    """
  end

  test "paperize={false} drops the click handler too, even with ripple defaulting true" do
    html = render_component(&bare/1)
    refute html =~ "onclick="
  end

  defp bare(assigns) do
    ~H"""
    <.pp_toggle_button paperize={false}>Bold</.pp_toggle_button>
    """
  end

  test "shows a pointer cursor on hover" do
    html = render_component(&unpressed/1)
    assert html =~ "cursor-pointer"
  end

  describe "toggle (client-side)" do
    alias Phoenix.LiveView.JS

    test "flips aria-pressed with a JS toggle_attribute, styled off aria-pressed" do
      assigns = %{}
      html = rendered_to_string(~H"<.pp_toggle_button toggle pressed>Bold</.pp_toggle_button>")

      assert html =~ ~s(aria-pressed="true")
      assert html =~ "toggle_attr"
      assert html =~ "aria-pressed:bg-pp-primary"
      assert html =~ "aria-pressed:hover:bg-pp-primary"
      # the static pressed classes aren't baked in: the client owns the state
      refute html =~ ~r/class="[^"]*(?<![:\w-])bg-pp-primary /
    end

    test "toggle_group un-presses the group, then presses itself, then runs on_toggle" do
      assert PhoenixPaper.ToggleButton.toggle_js("view", JS.push("changed")).ops == [
               [
                 "set_attr",
                 %{to: ~s([data-pp-toggle-group="view"]), attr: ["aria-pressed", "false"]}
               ],
               ["set_attr", %{attr: ["aria-pressed", "true"]}],
               ["push", %{event: "changed"}]
             ]
    end

    test "toggle_group implies toggle and marks the button with its group" do
      assigns = %{}

      html =
        rendered_to_string(~H"<.pp_toggle_button toggle_group='view'>Grid</.pp_toggle_button>")

      assert html =~ ~s(data-pp-toggle-group="view")
      assert html =~ "set_attr"
      assert html =~ ~s(aria-pressed="false")
    end

    test "controlled mode renders no JS commands of its own" do
      assigns = %{}
      html = rendered_to_string(~H"<.pp_toggle_button pressed>Bold</.pp_toggle_button>")
      refute html =~ "phx-click"
      refute html =~ "aria-pressed:"
    end

    test "paperize={false} keeps the toggling but drops the styling" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H"<.pp_toggle_button toggle paperize={false} class='mine'>B</.pp_toggle_button>"
        )

      assert html =~ "toggle_attr"
      assert html =~ "mine"
      refute html =~ "aria-pressed:bg"
    end
  end
end
