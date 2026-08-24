defmodule PhoenixPaper.Elevation do
  @moduledoc """
  Material Design elevation (dp 0-24) as Tailwind utility classes.

  The actual `box-shadow` values are defined once, in CSS, in
  `priv/static/phoenix_paper.css` as `@utility pp-elevation-0` .. `pp-elevation-24`.
  This module only maps an integer level to the matching class name.

  Class names below are written as full literal strings (never built with
  string interpolation) so Tailwind's static source scanner can find them in
  this file — see the "Tailwind class safety" rule in `AGENTS.md`.
  """

  @type level :: 0..24

  @doc """
  Returns the `pp-elevation-N` class for the given level, clamped to 0..24.

      iex> PhoenixPaper.Elevation.class(4)
      "pp-elevation-4"

      iex> PhoenixPaper.Elevation.class(99)
      "pp-elevation-24"
  """
  @spec class(integer()) :: String.t()
  def class(level) when is_integer(level) and level <= 0, do: "pp-elevation-0"
  def class(0), do: "pp-elevation-0"
  def class(1), do: "pp-elevation-1"
  def class(2), do: "pp-elevation-2"
  def class(3), do: "pp-elevation-3"
  def class(4), do: "pp-elevation-4"
  def class(5), do: "pp-elevation-5"
  def class(6), do: "pp-elevation-6"
  def class(7), do: "pp-elevation-7"
  def class(8), do: "pp-elevation-8"
  def class(9), do: "pp-elevation-9"
  def class(10), do: "pp-elevation-10"
  def class(11), do: "pp-elevation-11"
  def class(12), do: "pp-elevation-12"
  def class(13), do: "pp-elevation-13"
  def class(14), do: "pp-elevation-14"
  def class(15), do: "pp-elevation-15"
  def class(16), do: "pp-elevation-16"
  def class(17), do: "pp-elevation-17"
  def class(18), do: "pp-elevation-18"
  def class(19), do: "pp-elevation-19"
  def class(20), do: "pp-elevation-20"
  def class(21), do: "pp-elevation-21"
  def class(22), do: "pp-elevation-22"
  def class(23), do: "pp-elevation-23"
  def class(level) when is_integer(level) and level >= 24, do: "pp-elevation-24"
end
