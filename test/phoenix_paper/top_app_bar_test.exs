defmodule PhoenixPaper.TopAppBarTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.TopAppBar

  test "small (default): surface-colored, title-large title, scroll color change" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_top_app_bar>
        <:leading><button>menu</button></:leading>
        Inbox
        <:actions><button>more</button></:actions>
      </.pp_top_app_bar>
      """)

    assert html =~ ~s(data-pp-component="top-app-bar")
    assert html =~ "bg-pp-surface text-pp-on-surface"
    assert html =~ "pp-top-app-bar-scroll"
    assert html =~ "data-pp-scrolled:bg-pp-surface-container"
    assert html =~ "pp-title-large"
    assert html =~ "h-16"
    refute html =~ "bg-pp-primary"
  end

  test "center_aligned centers the title" do
    assigns = %{}

    html =
      rendered_to_string(~H"<.pp_top_app_bar variant='center_aligned'>Title</.pp_top_app_bar>")

    assert html =~ "grid-cols-[1fr_auto_1fr]"
    assert html =~ "text-center"
  end

  test "medium/large flexible: title on its own row in headline-medium / display-small, with subtitle" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_top_app_bar variant="medium" subtitle="3 unread">Inbox</.pp_top_app_bar>
      <.pp_top_app_bar variant="large">Inbox</.pp_top_app_bar>
      """)

    assert html =~ "pp-headline-medium"
    assert html =~ "pp-display-small"
    assert html =~ "3 unread"
  end

  test "scrolled forces the scrolled color; transparent drops the background" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_top_app_bar scrolled>A</.pp_top_app_bar>
      <.pp_top_app_bar color="transparent">B</.pp_top_app_bar>
      """)

    assert html =~ "data-pp-scrolled"
    [_, transparent] = String.split(html, "</header>", parts: 2)
    refute transparent =~ "bg-pp-surface "
  end

  test "positions are z-20, sticky pins to the top" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_top_app_bar position='sticky'>A</.pp_top_app_bar>")
    assert html =~ "sticky top-0 z-20"
  end

  test "max_width caps the content; disable_gutters drops padding" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_top_app_bar max_width="lg" disable_gutters>A</.pp_top_app_bar>
      """)

    assert html =~ "max-w-screen-lg"
    assert html =~ "px-0"
  end

  test "no phx-hook unless the app opted in and an id is given" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_top_app_bar id='bar'>A</.pp_top_app_bar>")
    refute html =~ "phx-hook"
  end

  test "paperize={false} keeps the row layout but drops the skin" do
    assigns = %{}

    html =
      rendered_to_string(~H"<.pp_top_app_bar paperize={false} class='mine'>A</.pp_top_app_bar>")

    refute html =~ "bg-pp-surface"
    assert html =~ "mine"
    assert html =~ "grid h-16"
  end
end
