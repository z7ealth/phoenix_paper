defmodule PhoenixPaper.CardTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Card

  test "renders title, body and actions slots" do
    html = render_component(&card/1)

    assert html =~ "bg-pp-surface"
    assert html =~ "Account"
    assert html =~ "You have no pending invoices."
    assert html =~ "Dismiss"
  end

  defp card(assigns) do
    ~H"""
    <.pp_card>
      <:title>Account</:title>
      You have no pending invoices.
      <:actions>
        <button>Dismiss</button>
      </:actions>
    </.pp_card>
    """
  end

  test "paperize={false} drops built-in classes" do
    html = render_component(&bare/1)
    refute html =~ "bg-pp-surface"
    assert html =~ "my-card"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_card paperize={false} class="my-card">Body</.pp_card>
    """
  end

  describe "link mode" do
    defp linked_card(assigns) do
      ~H"""
      <PhoenixPaper.Card.pp_card navigate="/components" padding={:lg}>
        <:title>Title</:title>
        Body
        <:actions><button>Act</button></:actions>
      </PhoenixPaper.Card.pp_card>
      """
    end

    test "wraps title and body in a link with hover, focus and ripple" do
      html = render_component(&linked_card/1)

      [link] = Regex.run(~r/<a[^>]*data-pp-card-action-area[^>]*>/, html)
      assert link =~ ~s(href="/components")
      assert link =~ "data-phx-link"
      assert link =~ "hover:after:bg-pp-on-surface/5"
      assert link =~ "focus-visible:after:outline-pp-primary"
      assert link =~ "p-6"
      assert link =~ "onclick="
      assert html =~ "overflow-hidden"
    end

    test "the link is stretched over the whole card, actions row included" do
      html = render_component(&linked_card/1)

      [root] = Regex.run(~r/<div[^>]*data-pp-component="card"[^>]*>/, html)
      assert root =~ ~r/[" ]relative[" ]/

      [link] = Regex.run(~r/<a[^>]*data-pp-card-action-area[^>]*>/, html)
      assert link =~ "after:absolute after:inset-0"

      [actions] = Regex.run(~r/<div[^>]*data-pp-card-actions[^>]*>/, html)
      assert actions =~ "relative z-10 pointer-events-none [&amp;&gt;*]:pointer-events-auto"
    end

    test "paperize: false keeps the stretch (it's what's clickable) but drops the skin" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <PhoenixPaper.Card.pp_card href="/x" paperize={false}>
          Body<:actions><button>A</button></:actions>
        </PhoenixPaper.Card.pp_card>
        """)

      assert html =~ "after:absolute after:inset-0"
      assert html =~ "relative z-10"
      refute html =~ "hover:after:bg"
    end

    test "keeps actions outside the link" do
      html = render_component(&linked_card/1)
      [_, after_link] = String.split(html, "</a>", parts: 2)
      assert after_link =~ "<button>Act</button>"
      [inside_link | _] = String.split(html, "</a>", parts: 2)
      refute inside_link =~ "Act"
    end

    test "a card without href/navigate/patch renders no link" do
      assigns = %{}
      html = rendered_to_string(~H"<PhoenixPaper.Card.pp_card>Body</PhoenixPaper.Card.pp_card>")
      refute html =~ "<a"
    end

    test "ripple is off under paperize: false" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H"<PhoenixPaper.Card.pp_card href='/x' paperize={false} class='mine'>Body</PhoenixPaper.Card.pp_card>"
        )

      refute html =~ "onclick="
      refute html =~ "hover:bg-pp-on-surface/5"
      assert html =~ "mine"
    end
  end

  test "target and rel go on the link, not the card root" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhoenixPaper.Card.pp_card href="https://example.com" target="_blank" rel="noopener">
        Body
      </PhoenixPaper.Card.pp_card>
      """)

    [link] = Regex.run(~r/<a[^>]*>/, html)
    assert link =~ ~s(target="_blank")
    assert link =~ ~s(rel="noopener")

    [root] = Regex.run(~r/<div[^>]*data-pp-component="card"[^>]*>/, html)
    refute root =~ "target="
  end
end
