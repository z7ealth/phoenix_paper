defmodule PhoenixPaper.FlashTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Flash

  defp render_group(flash, opts \\ []) do
    assigns = %{flash: flash, opts: Map.new(opts)}

    render_component(
      fn assigns ->
        ~H"""
        <.pp_flash_group
          flash={@flash}
          auto_hide_duration={@opts[:auto_hide_duration]}
          kinds={@opts[:kinds] || [:info, :error]}
        />
        """
      end,
      assigns
    )
  end

  test "renders one inverted-surface chip per present flash key, and nothing for absent keys" do
    html = render_group(%{"info" => "Saved!"})

    assert html =~ "Saved!"
    assert html =~ "bg-pp-on-surface"
    assert html =~ ~s(id="pp-flash-info")
    refute html =~ ~s(id="pp-flash-error")
  end

  test "empty flash renders the stack container but no chips" do
    html = render_group(%{})
    refute html =~ "data-pp-component=\"snackbar\""
    assert html =~ "data-pp-component=\"flash-group\""
  end

  test "dismiss is wired to LiveView's built-in lv:clear-flash for that key" do
    html = render_group(%{"error" => "Nope"})

    assert html =~ "data-pp-snackbar-close"
    assert html =~ "lv:clear-flash"
    assert html =~ "error"
  end

  test "error uses role=alert; info uses role=status" do
    assert render_group(%{"error" => "Nope"}) =~ ~s(role="alert")
    assert render_group(%{"info" => "Yep"}) =~ ~s(role="status")
  end

  test "auto_hide_duration threads through to each chip's CSS timer" do
    html = render_group(%{"info" => "Saved!"}, auto_hide_duration: 3000)
    assert html =~ "--pp-snackbar-timeout: 3000ms"
  end

  test "custom kinds are supported, unknown kinds render without an icon" do
    html = render_group(%{"warning" => "Careful"}, kinds: [:warning])
    assert html =~ "Careful"
    assert html =~ "hero-exclamation-triangle-mini"
  end
end
