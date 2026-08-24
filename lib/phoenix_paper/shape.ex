defmodule PhoenixPaper.Shape do
  @moduledoc """
  Material's corner-radius scale as Tailwind classes, so components share
  one consistent set of tokens instead of hand-picking `rounded-*` per
  component. As with `PhoenixPaper.Elevation`/`PhoenixPaper.Spacing`, every
  class is a full literal string (never interpolated) so Tailwind's static
  scanner can find it in this file.
  """

  @type token :: :none | :xs | :sm | :md | :lg | :xl | :full
  @type edge :: :all | :top | :bottom

  @doc """
  Returns the Tailwind class rounding all four corners to `token`.

      iex> PhoenixPaper.Shape.class(:lg)
      "rounded-lg"
  """
  @spec class(token()) :: String.t()
  def class(token), do: class(token, :all)

  @doc """
  Returns the Tailwind class rounding only the `edge` (`:top` or `:bottom`)
  corners to `token` — used by components like the filled text field, whose
  Material spec only rounds the top corners.

      iex> PhoenixPaper.Shape.class(:lg, :top)
      "rounded-t-lg"
  """
  @spec class(token(), edge()) :: String.t()
  def class(:none, :all), do: "rounded-none"
  def class(:xs, :all), do: "rounded-sm"
  def class(:sm, :all), do: "rounded"
  def class(:md, :all), do: "rounded-md"
  def class(:lg, :all), do: "rounded-lg"
  def class(:xl, :all), do: "rounded-xl"
  def class(:full, :all), do: "rounded-full"

  def class(:none, :top), do: "rounded-t-none"
  def class(:xs, :top), do: "rounded-t-sm"
  def class(:sm, :top), do: "rounded-t"
  def class(:md, :top), do: "rounded-t-md"
  def class(:lg, :top), do: "rounded-t-lg"
  def class(:xl, :top), do: "rounded-t-xl"
  def class(:full, :top), do: "rounded-t-full"

  def class(:none, :bottom), do: "rounded-b-none"
  def class(:xs, :bottom), do: "rounded-b-sm"
  def class(:sm, :bottom), do: "rounded-b"
  def class(:md, :bottom), do: "rounded-b-md"
  def class(:lg, :bottom), do: "rounded-b-lg"
  def class(:xl, :bottom), do: "rounded-b-xl"
  def class(:full, :bottom), do: "rounded-b-full"
end
