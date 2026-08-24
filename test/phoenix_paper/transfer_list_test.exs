defmodule PhoenixPaper.TransferListTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "starts with every item in the left list" do
    html =
      render_component(PhoenixPaper.TransferList,
        id: "perms",
        items: ["Read", "Write", "Admin"]
      )

    assert html =~ "Available (3)"
    assert html =~ "Selected (0)"
    assert html =~ "Read"
  end
end
