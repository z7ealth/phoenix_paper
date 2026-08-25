defmodule PhoenixPaper.Helpers do
  @moduledoc """
  Shared helpers used by every `PhoenixPaper` component to implement the
  `paperize` contract (see `AGENTS.md`).
  """

  @doc """
  Resolves the final `class` value for a component given its `paperize` flag.

  When `paperize` is `true`, the component's Material Design classes are kept
  and merged with the caller-supplied `class` using `PhoenixPaper.Tails` (so
  conflicting Tailwind utilities are deduplicated, last one wins) — that's a
  `Tails.Custom` instance rather than plain `Tails`, so it recognizes our
  `pp-*` color tokens; see its moduledoc for why that distinction matters.

  When `paperize` is `false`, the component's built-in classes are dropped
  entirely — only the caller-supplied `class` is rendered, giving the caller
  a bare, unstyled element to skin with their own CSS.
  """
  @spec classes(boolean(), Tails.input(), Tails.input()) :: String.t()
  def classes(paperize, paper_classes, extra_class)

  def classes(true, paper_classes, extra_class),
    do: PhoenixPaper.Tails.classes([paper_classes, extra_class])

  def classes(false, _paper_classes, extra_class), do: PhoenixPaper.Tails.classes([extra_class])

  @doc """
  The classes for a toggle control's wrapping `<label>` — `Checkbox`,
  `Switch`, and each of `RadioGroup`'s per-option labels all need the same
  `inline-flex items-center gap-2` to arrange their box/track next to the
  label text.

  Unlike `classes/3`, this is **not** gated behind `paperize` — it's always
  merged in via `PhoenixPaper.Tails`, `extra_class` and all. This layout
  isn't part of the "paper" skin `paperize={false}` is meant to strip
  (compare `paperize`'s own doc: colors/elevation/shape/typography); it's
  the structural arrangement of the label itself, and there's no other
  `class` attr on that specific label for a caller to rebuild it with —
  same reasoning as `AppBar`'s inner toolbar `<div>` and `Breadcrumbs`'s
  `<li>`s (see AGENTS.md, "The `paperize` contract"). Dropping it doesn't
  give `paperize={false}` a cleaner slate, it just breaks the box-plus-text
  layout with no way back — found from a real screenshot of `Checkbox`'s
  `paperize={false}` demo where the caller's own `class="size-5"` (meant to
  size the bare `<input>`, since that's the one truly skinnable element
  left when `paperize={false}`) landed on this label instead and shrank
  the whole row to nothing. `Checkbox`/`Switch` fixed the *targeting* half
  of that bug by routing `class` to the bare input instead of this label
  when `paperize={false}`; this function fixes the *layout* half so the
  label never collapses either way.
  """
  @spec toggle_label_classes(Tails.input()) :: String.t()
  def toggle_label_classes(extra_class),
    do:
      PhoenixPaper.Tails.classes([
        "inline-flex items-center gap-2 cursor-pointer select-none",
        extra_class
      ])

  @doc """
  Interpolates a `Phoenix.HTML.FormField` error tuple's `%{key}` placeholders
  (e.g. `{"must be %{count} characters", [count: 3]}`), without depending on
  Gettext. Shared by every form component (`Input`, `Select`,
  `NumberField`, ...) that accepts `field=` and renders `field.errors`.
  """
  @spec translate_error({String.t(), keyword()}) :: String.t()
  def translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
