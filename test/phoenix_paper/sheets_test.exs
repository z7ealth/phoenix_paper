defmodule PhoenixPaper.SheetsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.BottomSheet
  import PhoenixPaper.SideSheet

  test "modal bottom sheet: dialog wiring, drag handle, MD3 surface" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_bottom_sheet id='share' label='Share'><p>Body</p></.pp_bottom_sheet>"
      )

    assert html =~ ~s(id="share")
    assert html =~ "data-cancel"
    assert html =~ ~s(aria-modal="true")
    assert html =~ "bg-pp-scrim/32"
    assert html =~ "rounded-t-pp-xl bg-pp-surface-container-low"
    assert html =~ "data-pp-sheet-handle"
    assert html =~ ~s(id="share-handle")
    assert html =~ "max-w-[640px]"
  end

  test "BottomSheet.show/hide slide on the y axis" do
    show = PhoenixPaper.BottomSheet.show("share")
    assert inspect(show) =~ "translate-y-full"
    assert inspect(PhoenixPaper.BottomSheet.hide("share")) =~ "pop_focus"
  end

  test "standard bottom sheet renders in place without a scrim" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_bottom_sheet id='s' variant='standard'><p>Body</p></.pp_bottom_sheet>"
      )

    assert html =~ "<section"
    refute html =~ "bg-pp-scrim"
  end

  test "modal side sheet: header with title and close, actions behind a divider" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_side_sheet id="filters">
        <:title>Filters</:title>
        Content
        <:actions><button>Apply</button></:actions>
      </.pp_side_sheet>
      """)

    assert html =~ ~s(aria-labelledby="filters-title")
    assert html =~ "rounded-s-pp-lg bg-pp-surface-container-low"
    assert html =~ "pp-title-large"
    assert html =~ ~s(aria-label="Close")
    assert html =~ "border-t border-pp-outline-variant"
    assert html =~ "Apply"
  end

  test "standard side sheet is an aside with a start divider" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_side_sheet id='d' variant='standard'><:title>Details</:title>x</.pp_side_sheet>"
      )

    assert html =~ "<aside"
    assert html =~ "border-s border-pp-outline-variant"
    refute html =~ ~s(aria-label="Close")
  end

  # A modal opened, closed and opened again must look like the first open:
  # every element hide/2 hides has to be shown again by show/2. The scrim
  # (`#<id>-backdrop`) once wasn't, so from the second open it was missing.
  describe "show/2 undoes everything hide/2 hides" do
    defp targets(%Phoenix.LiveView.JS{ops: ops}, kind) do
      for [op, args] <- ops, op == kind, do: args[:to] || args["to"]
    end

    for module <- [PhoenixPaper.Dialog, PhoenixPaper.BottomSheet, PhoenixPaper.SideSheet] do
      test inspect(module) do
        module = unquote(module)
        hidden = targets(module.hide("m"), "hide")
        shown = targets(module.show("m"), "show")

        assert "#m-backdrop" in hidden
        assert hidden -- shown == []
      end
    end
  end
end
