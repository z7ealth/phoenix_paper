defmodule PhoenixPaper.Shape do
  @moduledoc """
  MD3's corner scale (including the M3 Expressive additions) as Tailwind
  classes backed by the `--radius-pp-*` tokens in `phoenix_paper.css`.

  | Token            | MD3 name               | Radius |
  |------------------|------------------------|--------|
  | `:none`          | none                   | 0      |
  | `:xs`            | extra-small            | 4px    |
  | `:sm`            | small                  | 8px    |
  | `:md`            | medium                 | 12px   |
  | `:lg`            | large                  | 16px   |
  | `:lg_increased`  | large-increased        | 20px   |
  | `:xl`            | extra-large            | 28px   |
  | `:xl_increased`  | extra-large-increased  | 32px   |
  | `:xxl`           | extra-extra-large      | 48px   |
  | `:full`          | full                   | pill   |

  Tailwind's own `rounded-*` steps don't line up with this scale
  (`rounded-lg` is 8px), so components never use them directly. Override
  a radius app-wide by redefining `--radius-pp-*` in your CSS.

  As everywhere in PhoenixPaper, every class is a literal string so
  Tailwind's scanner finds it in this file.
  """

  @type token ::
          :none | :xs | :sm | :md | :lg | :lg_increased | :xl | :xl_increased | :xxl | :full
  @type edge :: :all | :top | :bottom | :start | :end

  @tokens ~w(none xs sm md lg lg_increased xl xl_increased xxl full)a

  @doc "Every shape token, smallest first — handy for an attr's `values:`."
  @spec tokens() :: [token()]
  def tokens, do: @tokens

  @doc """
  Returns the class rounding all four corners to `token`.

      iex> PhoenixPaper.Shape.class(:md)
      "rounded-pp-md"
  """
  @spec class(token()) :: String.t()
  def class(token), do: class(token, :all)

  @doc """
  Returns the class rounding only one `edge`'s corners to `token` — the
  filled text field rounds only its top, a connected button group's end
  buttons only their outer side.

      iex> PhoenixPaper.Shape.class(:xs, :top)
      "rounded-t-pp-xs"
  """
  @spec class(token(), edge()) :: String.t()
  def class(:none, :all), do: "rounded-pp-none"
  def class(:xs, :all), do: "rounded-pp-xs"
  def class(:sm, :all), do: "rounded-pp-sm"
  def class(:md, :all), do: "rounded-pp-md"
  def class(:lg, :all), do: "rounded-pp-lg"
  def class(:lg_increased, :all), do: "rounded-pp-lg-increased"
  def class(:xl, :all), do: "rounded-pp-xl"
  def class(:xl_increased, :all), do: "rounded-pp-xl-increased"
  def class(:xxl, :all), do: "rounded-pp-xxl"
  def class(:full, :all), do: "rounded-pp-full"

  def class(:none, :top), do: "rounded-t-pp-none"
  def class(:xs, :top), do: "rounded-t-pp-xs"
  def class(:sm, :top), do: "rounded-t-pp-sm"
  def class(:md, :top), do: "rounded-t-pp-md"
  def class(:lg, :top), do: "rounded-t-pp-lg"
  def class(:lg_increased, :top), do: "rounded-t-pp-lg-increased"
  def class(:xl, :top), do: "rounded-t-pp-xl"
  def class(:xl_increased, :top), do: "rounded-t-pp-xl-increased"
  def class(:xxl, :top), do: "rounded-t-pp-xxl"
  def class(:full, :top), do: "rounded-t-pp-full"

  def class(:none, :bottom), do: "rounded-b-pp-none"
  def class(:xs, :bottom), do: "rounded-b-pp-xs"
  def class(:sm, :bottom), do: "rounded-b-pp-sm"
  def class(:md, :bottom), do: "rounded-b-pp-md"
  def class(:lg, :bottom), do: "rounded-b-pp-lg"
  def class(:lg_increased, :bottom), do: "rounded-b-pp-lg-increased"
  def class(:xl, :bottom), do: "rounded-b-pp-xl"
  def class(:xl_increased, :bottom), do: "rounded-b-pp-xl-increased"
  def class(:xxl, :bottom), do: "rounded-b-pp-xxl"
  def class(:full, :bottom), do: "rounded-b-pp-full"

  def class(:none, :start), do: "rounded-s-pp-none"
  def class(:xs, :start), do: "rounded-s-pp-xs"
  def class(:sm, :start), do: "rounded-s-pp-sm"
  def class(:md, :start), do: "rounded-s-pp-md"
  def class(:lg, :start), do: "rounded-s-pp-lg"
  def class(:lg_increased, :start), do: "rounded-s-pp-lg-increased"
  def class(:xl, :start), do: "rounded-s-pp-xl"
  def class(:xl_increased, :start), do: "rounded-s-pp-xl-increased"
  def class(:xxl, :start), do: "rounded-s-pp-xxl"
  def class(:full, :start), do: "rounded-s-pp-full"

  def class(:none, :end), do: "rounded-e-pp-none"
  def class(:xs, :end), do: "rounded-e-pp-xs"
  def class(:sm, :end), do: "rounded-e-pp-sm"
  def class(:md, :end), do: "rounded-e-pp-md"
  def class(:lg, :end), do: "rounded-e-pp-lg"
  def class(:lg_increased, :end), do: "rounded-e-pp-lg-increased"
  def class(:xl, :end), do: "rounded-e-pp-xl"
  def class(:xl_increased, :end), do: "rounded-e-pp-xl-increased"
  def class(:xxl, :end), do: "rounded-e-pp-xxl"
  def class(:full, :end), do: "rounded-e-pp-full"
end
