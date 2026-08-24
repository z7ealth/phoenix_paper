defmodule PhoenixPaper.TailsTest do
  use ExUnit.Case, async: true

  # Regression test for a real bug: plain `Tails` doesn't recognize `pp-*`
  # as a color, so combining a Tailwind utility that shares a prefix with a
  # `pp-*` color class (font-size and color both start `text-`; width and
  # color both start `outline-`/`border-`) got treated as one conflicting
  # group, silently dropping one of the two. `PhoenixPaper.Tails` is a
  # `Tails.Custom` instance told about our color tokens specifically to fix
  # this — see its moduledoc and AGENTS.md for the full story, including
  # why the fix lives in `mix.exs` rather than a config file.

  test "keeps a font-size utility alongside a pp-* text color" do
    result = PhoenixPaper.Tails.classes(["text-xs font-normal text-pp-on-surface/70", nil])

    assert result =~ "text-xs"
    assert result =~ "text-pp-on-surface/70"
  end

  test "keeps outline-2 (width) alongside outline-pp-primary (color) — the real Button focus-ring pattern" do
    result =
      PhoenixPaper.Tails.classes([
        "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-pp-primary",
        nil
      ])

    assert result =~ "focus-visible:outline-2"
    assert result =~ "focus-visible:outline-offset-2"
    assert result =~ "focus-visible:outline-pp-primary"
  end

  test "PhoenixPaper.Helpers.classes/3 (what every component actually calls) doesn't drop either" do
    result = PhoenixPaper.Helpers.classes(true, "bg-pp-primary text-sm text-pp-on-primary", nil)

    assert result =~ "text-sm"
    assert result =~ "text-pp-on-primary"
  end
end
