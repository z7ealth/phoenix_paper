defmodule PhoenixPaper.ThemeToggleTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ThemeToggle

  describe "segmented (default)" do
    defp segmented(assigns) do
      ~H"""
      <.pp_theme_toggle on_toggle={Phoenix.LiveView.JS.push("save_theme")} />
      """
    end

    test "renders System, Light and Dark buttons" do
      html = render_component(&segmented/1)

      assert html =~ ~s(role="group" aria-label="Theme")

      for {mode, icon} <- [
            {"system", "hero-computer-desktop-micro"},
            {"light", "hero-sun-micro"},
            {"dark", "hero-moon-micro"}
          ] do
        assert html =~ ~s(data-pp-theme="#{mode}")
        assert html =~ ~s(phx-value-theme="#{mode}")
        assert html =~ icon
      end

      refute html =~ ~s(type="checkbox")
    end

    test "System removes data-theme, Light/Dark set it explicitly" do
      html = render_component(&segmented/1)

      assert html =~ "t.removeAttribute(&#39;data-theme&#39;)"
      assert html =~ "t.setAttribute(&#39;data-theme&#39;,m)"
      assert html =~ "var m=&quot;system&quot;"
      assert html =~ "var m=&quot;dark&quot;"
    end

    test "remembers the choice under phx:theme, removing it for System" do
      html = render_component(&segmented/1)
      assert html =~ "localStorage.removeItem(&#39;phx:theme&#39;)"
      assert html =~ "m===&#39;system&#39;?null:m"
    end

    test "the selected state is pure CSS keyed off the ancestor data-theme, System when none" do
      html = render_component(&segmented/1)

      assert html =~ "[[data-theme=light]_&amp;]:translate-x-8"
      assert html =~ "[[data-theme=dark]_&amp;]:translate-x-16"
      refute html =~ "<script>"
    end

    test "on_toggle is wired as phx-click on every button" do
      html = render_component(&segmented/1)
      assert length(Regex.scan(~r/phx-click="[^"]*save_theme/, html)) == 3
    end

    test "a scoped target neither persists nor touches html" do
      assigns = %{}
      html = rendered_to_string(~H"<.pp_theme_toggle target='#preview' />")
      assert html =~ "querySelector(&quot;#preview&quot;)"
      refute html =~ "localStorage"
    end

    test "label shows visible text when given" do
      assigns = %{}
      html = rendered_to_string(~H"<.pp_theme_toggle label='Theme' />")
      assert html =~ "<span>Theme</span>"
    end

    test "paperize={false} drops the built-in classes but keeps the buttons working" do
      assigns = %{}
      html = rendered_to_string(~H"<.pp_theme_toggle paperize={false} class='mine' />")
      assert html =~ "mine"
      assert html =~ "t.removeAttribute"
      refute html =~ "bg-pp-secondary-container"
      refute html =~ "translate-x-8"
      refute html =~ "onclick=\"(function(e){"
    end
  end
end
