defmodule PhoenixPaper.AutocompleteTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "renders every option in the closed dropdown's initial state" do
    html =
      render_component(PhoenixPaper.Autocomplete,
        id: "country",
        name: "country",
        label: "Country",
        options: ["Canada", "Mexico"]
      )

    assert html =~ "Country"
    refute html =~ "Canada"
    refute html =~ "Mexico"
  end

  test "update/2 seeds the query from a preselected value's label" do
    html =
      render_component(PhoenixPaper.Autocomplete,
        id: "country",
        name: "country",
        options: [{"Canada", "ca"}, {"Mexico", "mx"}],
        value: "mx"
      )

    assert html =~ ~s(value="Mexico")
  end
end
