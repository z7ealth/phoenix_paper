defmodule PhoenixPaper.Spacing do
  @moduledoc """
  Named spacing tokens on top of Tailwind's default scale (which is already
  a 4px/0.25rem grid, compatible with Material's 8dp baseline grid).

  Components should reference these tokens instead of raw Tailwind spacing
  numbers so a project-wide density change is a one-file edit. As with
  `PhoenixPaper.Elevation`, every class is a full literal string (never
  interpolated) so Tailwind's static scanner can find it in this file.
  """

  @type token :: :none | :xs | :sm | :md | :lg | :xl | :"2xl"

  @doc """
  Returns the Tailwind padding class (`p-*`) for a spacing token.
  """
  @spec padding(token()) :: String.t()
  def padding(:none), do: "p-0"
  def padding(:xs), do: "p-1"
  def padding(:sm), do: "p-2"
  def padding(:md), do: "p-4"
  def padding(:lg), do: "p-6"
  def padding(:xl), do: "p-8"
  def padding(:"2xl"), do: "p-12"

  @doc """
  Returns the Tailwind gap class (`gap-*`) for a spacing token.
  """
  @spec gap(token()) :: String.t()
  def gap(:none), do: "gap-0"
  def gap(:xs), do: "gap-1"
  def gap(:sm), do: "gap-2"
  def gap(:md), do: "gap-4"
  def gap(:lg), do: "gap-6"
  def gap(:xl), do: "gap-8"
  def gap(:"2xl"), do: "gap-12"
end
