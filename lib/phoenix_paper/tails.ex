defmodule PhoenixPaper.Tails do
  @moduledoc """
  A `Tails.Custom` instance that knows about PhoenixPaper's `pp-*` color
  tokens, so its class-conflict merging correctly tells `text-xs`
  (font-size) apart from `text-pp-on-surface` (color) — both share the
  `text-` prefix, and the plain `Tails` module only recognizes Tailwind's
  own built-in palette names, so it can't classify `pp-*` as a color at
  all. When it can't, it falls back to treating same-prefixed classes as
  one conflicting group and keeps only the last one — which silently
  dropped real classes like `outline-2` (width) when combined with
  `outline-pp-primary` (color) in the same `class={}`, shrinking every
  focus ring in the library back to the browser default width.

  `PhoenixPaper.Helpers.classes/3` uses this instead of `Tails` directly.
  You shouldn't need to call it yourself — see `AGENTS.md` if you're
  wondering why this module (and its `mix.exs` setup) exists at all.
  """
  use Tails.Custom, otp_app: :phoenix_paper
end
