defmodule PhoenixPaper.ThemeToggleTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ThemeToggle

  test "renders a switch that computes the effective theme and flips to the opposite, explicitly" do
    html = render_component(&basic/1)

    assert html =~ "Dark mode"
    assert html =~ "querySelector(&quot;html&quot;)"
    assert html =~ "setAttribute(&#39;data-theme&#39;"
    assert html =~ "matchMedia(&#39;(prefers-color-scheme: dark)&#39;)"
    assert html =~ "isDark?&#39;light&#39;:&#39;dark&#39;"
  end

  defp basic(assigns) do
    ~H"""
    <.pp_theme_toggle variant="switch" />
    """
  end

  test "default_checked sets the switch's initial visual state" do
    html = render_component(&checked/1)
    assert html =~ "checked"
  end

  defp checked(assigns) do
    ~H"""
    <.pp_theme_toggle variant="switch" default_checked={true} />
    """
  end

  test "target scopes the toggle to a custom selector instead of html" do
    html = render_component(&scoped/1)
    assert html =~ "#preview"
  end

  defp scoped(assigns) do
    ~H"""
    <.pp_theme_toggle variant="switch" target="#preview" />
    """
  end

  test "label overrides the default \"Dark mode\" text" do
    html = render_component(&custom_label/1)
    assert html =~ "Light/Dark"
    refute html =~ "Dark mode"
  end

  defp custom_label(assigns) do
    ~H"""
    <.pp_theme_toggle variant="switch" label="Light/Dark" />
    """
  end

  test "on_toggle's JS commands are wired as phx-click, independent of the onclick data-theme flip" do
    html = render_component(&with_on_toggle/1)
    assert html =~ "save_theme_preference"
    assert html =~ "setAttribute(&#39;data-theme&#39;"
  end

  defp with_on_toggle(assigns) do
    ~H"""
    <.pp_theme_toggle variant="switch" on_toggle={Phoenix.LiveView.JS.push("save_theme_preference")} />
    """
  end

  test "paperize={false} drops the switch's built-in classes" do
    html = render_component(&bare/1)
    refute html =~ "has-[:checked]"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_theme_toggle variant="switch" paperize={false} />
    """
  end

  test "renders a sun icon and a moon icon inside the thumb" do
    html = render_component(&basic/1)

    assert html =~ "hero-sun-mini"
    assert html =~ "hero-moon-mini"
  end

  test "the icon size override uses !important — class overrides aren't merged, so ! is what wins" do
    html = render_component(&basic/1)
    assert html =~ "!size-3"
  end

  test "renders no inline <script> — the first-paint system sync is pure CSS, not JS" do
    html = render_component(&basic/1)
    refute html =~ "<script>"
  end

  test "the click handler never reads the checkbox's own checked property to decide direction" do
    html = render_component(&basic/1)
    refute html =~ "this.checked"
  end

  test "renders a data-pp-target attribute matching target, for cross-instance sync scoping" do
    html = render_component(&basic/1)
    assert html =~ "data-pp-target=\"html\""

    scoped_html = render_component(&scoped/1)
    assert scoped_html =~ "data-pp-target=\"#preview\""
  end

  test "the click handler syncs every other same-target toggle's checked property" do
    html = render_component(&basic/1)

    assert html =~
             "querySelectorAll(&quot;[data-pp-component=\\&quot;theme-toggle\\&quot;][data-pp-target=\\&quot;html\\&quot;] input[type=checkbox]&quot;)"

    assert html =~ "other.checked=(next==="
  end

  test "the sync query is scoped by target, so a scoped toggle doesn't reference the default html selector" do
    html = render_component(&scoped/1)

    assert html =~ "data-pp-target=\\&quot;#preview\\&quot;"
    refute html =~ "data-pp-target=\\&quot;html\\&quot;"
  end

  test "the switch remembers the choice under phx:theme for the page-wide target only" do
    assert render_component(&basic/1) =~ "localStorage.setItem(&#39;phx:theme&#39;,v)"
    refute render_component(&scoped/1) =~ "localStorage"
  end

  test "the switch's look follows an explicit data-theme, overriding its checkbox" do
    html = render_component(&basic/1)

    assert html =~ "[[data-theme=dark]_&amp;]:!translate-x-4"
    assert html =~ "[[data-theme=light]_&amp;]:!translate-x-0"
    assert html =~ "[[data-theme=dark]_&amp;]:[&amp;&gt;span:last-child]:!opacity-100"
    assert html =~ "[[data-theme=light]_&amp;]:[&amp;&gt;span:first-child]:!opacity-100"
    assert html =~ "[[data-theme=dark]_&amp;]:!bg-gray-500/70"
  end

  describe "segmented (default)" do
    defp segmented(assigns) do
      ~H"""
      <.pp_theme_toggle on_toggle={Phoenix.LiveView.JS.push("save_theme")} />
      """
    end

    test "is the default variant, with System, Light and Dark buttons" do
      html = render_component(&segmented/1)

      assert html =~ ~s(data-pp-variant="segmented")
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

      refute html =~ "Dark mode"
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

      assert html =~ "[[data-theme=light]_&amp;]:translate-x-7"
      assert html =~ "[[data-theme=dark]_&amp;]:translate-x-14"
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
      refute html =~ "bg-gray-500/25"
      refute html =~ "translate-x-7"
      refute html =~ "onclick=\"(function(e){"
    end
  end
end
