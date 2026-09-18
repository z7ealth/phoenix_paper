defmodule PhoenixPaper.TailsTest do
  use ExUnit.Case, async: true

  # Historical regression test: plain `Tails` (the `tails` hex package this
  # library used to depend on) didn't recognize `pp-*` as a color, so
  # combining a Tailwind utility that shares a prefix with a `pp-*` color
  # class (font-size and color both start `text-`; width and color both
  # start `outline-`/`border-`) got treated as one conflicting group,
  # silently dropping one of the two. That's what these assertions guarded
  # against.
  #
  # `tails` was retired on hex.pm with no maintained drop-in successor that
  # covers this, so `PhoenixPaper.Helpers.classes/3` no longer merges at
  # all — see AGENTS.md, "Overriding built-in classes via `class`". These
  # cases now pass trivially (plain concatenation never drops anything),
  # but they're kept as a sanity check that nothing accidentally
  # reintroduces class-dropping behavior later.

  test "keeps a font-size utility alongside a pp-* text color" do
    result = PhoenixPaper.Helpers.classes(true, "text-xs font-normal text-pp-on-surface/70", nil)

    assert result =~ "text-xs"
    assert result =~ "text-pp-on-surface/70"
  end

  test "keeps outline-2 (width) alongside outline-pp-primary (color) — the real Button focus-ring pattern" do
    result =
      PhoenixPaper.Helpers.classes(
        true,
        "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-pp-primary",
        nil
      )

    assert result =~ "focus-visible:outline-2"
    assert result =~ "focus-visible:outline-offset-2"
    assert result =~ "focus-visible:outline-pp-primary"
  end

  test "PhoenixPaper.Helpers.classes/3 (what every component actually calls) doesn't drop either" do
    result = PhoenixPaper.Helpers.classes(true, "bg-pp-primary text-sm text-pp-on-primary", nil)

    assert result =~ "text-sm"
    assert result =~ "text-pp-on-primary"
  end

  test "a caller's class is concatenated after the component's own, not merged" do
    result = PhoenixPaper.Helpers.classes(true, "bg-pp-primary", "!bg-red-500")

    assert result =~ "bg-pp-primary"
    assert result =~ "!bg-red-500"
  end
end
