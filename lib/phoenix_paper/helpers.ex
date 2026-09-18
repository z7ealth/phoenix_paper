defmodule PhoenixPaper.Helpers do
  @moduledoc """
  Shared helpers used by every `PhoenixPaper` component to implement the
  `paperize` contract (see `AGENTS.md`).
  """

  @typedoc """
  What a `class` attr can hold: `nil`/`false` (dropped), a string, or an
  arbitrarily nested list of either — the same shape HEEx's own `class={...}`
  attribute already accepts, so a caller's `@cond && "foo"` idiom works with
  no special-casing.
  """
  @type class_value :: nil | boolean() | String.t() | [class_value()]

  @doc """
  Resolves the final `class` value for a component given its `paperize` flag.

  When `paperize` is `true`, the component's Material Design classes are
  concatenated with the caller-supplied `class`. **This is plain
  concatenation, not a merge** — PhoenixPaper has no Tailwind class-conflict
  resolver (see `AGENTS.md`'s "Overriding built-in classes via `class`" for
  why), so if a caller's class targets the same CSS property as one of the
  component's own built-in classes, both render and which one visually wins
  is decided by Tailwind's own generated stylesheet order, not by the order
  of `class={...}`. A caller overriding a built-in utility should prefix
  their override with `!` (Tailwind's important-modifier) to win
  deterministically — see `AGENTS.md`.

  When `paperize` is `false`, the component's built-in classes are dropped
  entirely — only the caller-supplied `class` is rendered, giving the caller
  a bare, unstyled element to skin with their own CSS.
  """
  @spec classes(boolean(), class_value(), class_value()) :: String.t()
  def classes(paperize, paper_classes, extra_class)

  def classes(true, paper_classes, extra_class), do: join([paper_classes, extra_class])
  def classes(false, _paper_classes, extra_class), do: join([extra_class])

  @doc """
  The classes for a toggle control's wrapping `<label>` — `Checkbox`,
  `Switch`, and each of `RadioGroup`'s per-option labels all need the same
  `inline-flex items-center gap-2` to arrange their box/track next to the
  label text.

  Unlike `classes/3`, this is **not** gated behind `paperize` — it's always
  concatenated in, `extra_class` and all. This layout isn't part of the
  "paper" skin `paperize={false}` is meant to strip (compare `paperize`'s
  own doc: colors/elevation/shape/typography); it's the structural
  arrangement of the label itself, and there's no other `class` attr on
  that specific label for a caller to rebuild it with — same reasoning as
  `AppBar`'s inner toolbar `<div>` and `Breadcrumbs`'s `<li>`s (see
  AGENTS.md, "The `paperize` contract"). Dropping it doesn't give
  `paperize={false}` a cleaner slate, it just breaks the box-plus-text
  layout with no way back — found from a real screenshot of `Checkbox`'s
  `paperize={false}` demo where the caller's own `class="size-5"` (meant to
  size the bare `<input>`, since that's the one truly skinnable element
  left when `paperize={false}`) landed on this label instead and shrank
  the whole row to nothing. `Checkbox`/`Switch` fixed the *targeting* half
  of that bug by routing `class` to the bare input instead of this label
  when `paperize={false}`; this function fixes the *layout* half so the
  label never collapses either way.
  """
  @spec toggle_label_classes(class_value()) :: String.t()
  def toggle_label_classes(extra_class),
    do: join(["inline-flex items-center gap-2 cursor-pointer select-none", extra_class])

  # Flattens an arbitrarily nested list of class values (strings, `nil`,
  # `false`, or nested lists — see `t:class_value/0`) into a single
  # space-joined string, dropping anything falsy. No conflict resolution:
  # see `classes/3`'s doc for why.
  @spec join([class_value()]) :: String.t()
  defp join(value) do
    value
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, false, ""]))
    |> Enum.map_join(" ", &to_string/1)
  end

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
