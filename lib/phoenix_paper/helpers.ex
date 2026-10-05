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
  label text, and the `pp-state-group` marker their 40dp state-layer
  circle (`pp-state-layer-target`) reacts to.

  Unlike `classes/3`, this is **not** gated behind `paperize` — it's always
  concatenated in, `extra_class` and all. This layout isn't part of the
  "paper" skin `paperize={false}` is meant to strip (compare `paperize`'s
  own doc: colors/elevation/shape/typography); it's the structural
  arrangement of the label itself, and there's no other `class` attr on
  that specific label for a caller to rebuild it with — same reasoning as
  `TopAppBar`'s inner row `<div>` (see
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
    do:
      join([
        "pp-state-group inline-flex items-center gap-2 cursor-pointer select-none has-[:disabled]:cursor-default",
        extra_class
      ])

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
  The `phx-hook` value for components the PhoenixPaper JS hook enhances
  (tab indicator sliding, scroll-aware app bars, sheet dragging, carousel
  masking, loading-indicator morphing, time-picker dial dragging, edge
  flipping for menus and tooltips): `"PhoenixPaper"`, or `nil` when there's
  no DOM `id` (a LiveView hook requirement), in which case the element
  keeps its CSS-only behavior.

  The hook is part of PhoenixPaper's setup: register it in your
  LiveSocket (see the README). Every hooked component still renders and
  works without it running — on controller-rendered pages, and before
  LiveView connects — just without those enhancements.
  """
  @spec hook(String.t() | nil) :: String.t() | nil
  def hook(id \\ ""), do: if(id, do: "PhoenixPaper")

  @doc """
  Interpolates a `Phoenix.HTML.FormField` error tuple's `%{key}` placeholders
  (e.g. `{"must be %{count} characters", [count: 3]}`), without depending on
  Gettext. Shared by every form component (`TextField`, `Select`,
  `Checkbox`, ...) that accepts `field=` and renders `field.errors`.

  Only the placeholders the message actually contains are filled in; every
  other option is ignored. Ecto puts non-text metadata in the same keyword
  list (`unique_constraint`'s `fields: [:email]`, `constraint_name: ...`,
  `validation: {:format, ~r/.../}`), and converting those to text would
  raise. A placeholder with no matching option is left as written, and one
  whose value isn't plain text is rendered with `inspect/1`.

      iex> PhoenixPaper.Helpers.translate_error({"has already been taken", [constraint: :unique, fields: [:email]]})
      "has already been taken"

      iex> PhoenixPaper.Helpers.translate_error({"should be at least %{count} character(s)", [count: 3, validation: :length]})
      "should be at least 3 character(s)"
  """
  @spec translate_error({String.t(), keyword()}) :: String.t()
  def translate_error({msg, opts}) do
    Regex.replace(~r/%\{(\w+)\}/, msg, fn placeholder, key ->
      case Enum.find(opts, fn {opt_key, _value} -> to_string(opt_key) == key end) do
        {_key, value} -> placeholder_text(value)
        nil -> placeholder
      end
    end)
  end

  defp placeholder_text(value) when is_binary(value) or is_number(value) or is_atom(value),
    do: to_string(value)

  defp placeholder_text(value), do: inspect(value)
end
