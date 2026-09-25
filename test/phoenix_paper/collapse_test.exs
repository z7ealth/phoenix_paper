defmodule PhoenixPaper.CollapseTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Collapse

  defp collapse(assigns) do
    ~H"""
    <.pp_collapse id="more" trigger_class="my-trigger">
      <:trigger>Show more</:trigger>
      Hidden content
    </.pp_collapse>
    """
  end

  test "renders a hidden checkbox, a label trigger and grid-animated content as flat siblings" do
    html = render_component(&collapse/1)

    assert html =~ ~s(data-pp-component="collapse")
    assert html =~ ~r/<input type="checkbox" id="more-toggle"[^>]*class="peer sr-only"/
    assert html =~ ~s(for="more-toggle")
    assert html =~ ~s(aria-controls="more-content")
    assert html =~ ~s(id="more-content")
    assert html =~ "invisible grid grid-rows-[0fr]"
    assert html =~ "peer-checked:visible peer-checked:grid-rows-[1fr]"
    assert html =~ "Show more"
    assert html =~ "Hidden content"
    assert html =~ "my-trigger"
  end

  test "default paperize styles the trigger and shows a rotating chevron" do
    html = render_component(&collapse/1)

    assert html =~ "hover:bg-pp-on-surface/5"
    assert html =~ "hero-chevron-down-mini"
    assert html =~ "peer-checked:[&amp;&gt;[data-pp-collapse-icon]]:rotate-180"
  end

  test "default_open starts checked" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_collapse id="c" default_open>
        <:trigger>T</:trigger>
        x
      </.pp_collapse>
      """)

    assert html =~ ~r/<input[^>]*checked/
  end

  test "icon={false} drops the chevron" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_collapse id="c" icon={false}>
        <:trigger>T</:trigger>
        x
      </.pp_collapse>
      """)

    refute html =~ "hero-chevron-down-mini"
  end

  test "paperize={false} drops the skin but keeps the show/hide wiring" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_collapse id="c" paperize={false} class="mine">
        <:trigger>T</:trigger>
        x
      </.pp_collapse>
      """)

    assert html =~ "mine"
    assert html =~ "peer sr-only"
    assert html =~ "peer-checked:grid-rows-[1fr]"
    refute html =~ "hover:bg-pp-on-surface/5"
    refute html =~ "hero-chevron-down-mini"
  end
end
