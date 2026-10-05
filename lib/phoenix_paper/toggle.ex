defmodule PhoenixPaper.Toggle do
  @moduledoc """
  Client-side toggle wiring shared by M3 Expressive toggle buttons
  (`PhoenixPaper.Button`, `PhoenixPaper.IconButton`) and single-select
  `PhoenixPaper.ButtonGroup`s.

  A toggle button's selected look is styled off its own `aria-pressed`
  attribute (`aria-pressed:bg-pp-primary`, ...), never off an Elixir
  assign, so the same classes serve both modes:

  - **Controlled** (`selected={@bold}`, no `toggle`): the server renders
    `aria-pressed`, a click only fires the caller's own `phx-click`.
  - **Client-side** (`toggle`): the click runs `Phoenix.LiveView.JS`
    commands that flip `aria-pressed` with no round trip. JS commands and
    not an `onclick` on purpose: LiveView keeps attributes set by JS
    commands across later patches, while an `onclick`'s `setAttribute`
    would be reset to the server's value by the next unrelated re-render.

  With a `group` name the click un-presses every
  `[data-pp-toggle-group="<group>"]` element, then presses itself — an
  exclusive (single-select) group, where clicking the pressed member keeps
  it pressed.
  """

  alias Phoenix.LiveView.JS

  @doc """
  The `phx-click` commands for a client-side toggle: flip `aria-pressed`,
  or for a `group`, un-press the group and press this one. `extra` (a
  `%JS{}`, e.g. `JS.push("changed")`) runs afterwards.
  """
  @spec js(String.t() | nil, JS.t()) :: JS.t()
  def js(group, extra \\ %JS{})

  def js(nil, %JS{ops: extra}) do
    %JS{ops: JS.toggle_attribute({"aria-pressed", "true", "false"}).ops ++ extra}
  end

  def js(group, %JS{ops: extra}) do
    ops =
      {"aria-pressed", "false"}
      |> JS.set_attribute(to: ~s([data-pp-toggle-group="#{group}"]))
      |> JS.set_attribute({"aria-pressed", "true"})

    %JS{ops: ops.ops ++ extra}
  end

  @doc """
  The `aria-pressed` value for a toggle-capable button: `nil` (attribute
  dropped) for a plain button, `"true"`/`"false"` once it's a toggle —
  either `selected` was given, or `toggle`/`group` made it client-side.
  """
  @spec aria_pressed(boolean() | nil, boolean()) :: String.t() | nil
  def aria_pressed(nil, false), do: nil
  def aria_pressed(selected, _toggle?), do: to_string(selected == true)
end
