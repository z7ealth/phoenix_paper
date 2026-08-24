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
end
