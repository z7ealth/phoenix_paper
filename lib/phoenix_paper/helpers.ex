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
