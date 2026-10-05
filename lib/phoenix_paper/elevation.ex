defmodule PhoenixPaper.Elevation do
  @moduledoc """
  MD3 elevation levels (0-5) as Tailwind utility classes.

  MD3 has six levels — 0, 1, 3, 6, 8 and 12dp — instead of MD2's 0-24dp
  scale. In MD3 a surface's height is shown mostly by its
  *surface-container color* (see `PhoenixPaper.Paper`'s `color`), not by
  shadow: only a few components keep one (elevated button and card, FAB,
  menus, the navigation components when scrolled under). This module maps
  a level to the shadow utility; picking the matching container color is
  the component's job.

  | Level | dp | Typical use |
  |-------|----|-------------|
  | 0 | 0 | flat surfaces, filled/outlined cards |
  | 1 | 1 | elevated button/card, modal sheets |
  | 2 | 3 | menus, scrolled top app bar, navigation bar |
  | 3 | 6 | FAB, dialogs, search view, date/time pickers |
  | 4 | 8 | hovered FAB |
  | 5 | 12 | — (reserved by MD3) |

  The `box-shadow` values live in `priv/static/phoenix_paper.css` as
  `@utility pp-elevation-0` .. `pp-elevation-5`, built from
  `--color-pp-shadow`. Every class below is a full literal string so
  Tailwind's scanner finds it (see AGENTS.md, "Tailwind class safety").
  """

  @type level :: 0..5

  @doc """
  Returns the `pp-elevation-N` class for the given level, clamped to 0..5.

      iex> PhoenixPaper.Elevation.class(3)
      "pp-elevation-3"

      iex> PhoenixPaper.Elevation.class(12)
      "pp-elevation-5"
  """
  @spec class(integer()) :: String.t()
  def class(level) when is_integer(level) and level <= 0, do: "pp-elevation-0"
  def class(1), do: "pp-elevation-1"
  def class(2), do: "pp-elevation-2"
  def class(3), do: "pp-elevation-3"
  def class(4), do: "pp-elevation-4"
  def class(level) when is_integer(level) and level >= 5, do: "pp-elevation-5"

  @doc """
  Like `class/1`, but prefixed with `hover:` — for components whose
  elevation rises one level on hover (elevated button, FAB). Literal per
  level for the same scanner reason.

      iex> PhoenixPaper.Elevation.hover_class(2)
      "hover:pp-elevation-2"
  """
  @spec hover_class(integer()) :: String.t()
  def hover_class(level) when is_integer(level) and level <= 0, do: "hover:pp-elevation-0"
  def hover_class(1), do: "hover:pp-elevation-1"
  def hover_class(2), do: "hover:pp-elevation-2"
  def hover_class(3), do: "hover:pp-elevation-3"
  def hover_class(4), do: "hover:pp-elevation-4"
  def hover_class(level) when is_integer(level) and level >= 5, do: "hover:pp-elevation-5"
end
