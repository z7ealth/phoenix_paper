defmodule PhoenixPaper.Slider do
  @moduledoc """
  A Material Design slider (`pp_slider/1`) — a native `<input
  type="range">` colored via the CSS `accent-color` property rather than
  `::-webkit-slider-thumb`/`::-moz-range-thumb` pseudo-element overrides, so
  it stays visually consistent across browser engines without extra
  cross-browser hacks. Accent color is broadly supported in current
  evergreen browsers.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: nil)
  attr(:min, :any, default: 0)
  attr(:max, :any, default: 100)
  attr(:step, :any, default: 1)
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))
  attr(:label, :string, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form autofocus phx-change))

  def pp_slider(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:id, fn -> field.id end)
    |> assign_new(:value, fn -> field.value end)
    |> pp_slider()
  end

  def pp_slider(assigns) do
    ~H"""
    <div data-pp-component="slider" class={Helpers.classes(@paperize, "flex flex-col gap-1", @class)}>
      <div :if={@label} class="flex items-center justify-between text-sm">
        <span>{@label}</span>
        <span class="tabular-nums opacity-70">{@value}</span>
      </div>
      <input
        type="range"
        id={@id}
        name={@name}
        value={@value}
        min={@min}
        max={@max}
        step={@step}
        disabled={@disabled}
        class={Helpers.classes(@paperize, slider_classes(@color), nil)}
        {@rest}
      />
    </div>
    """
  end

  defp slider_classes(color) do
    [
      "h-2 w-full cursor-pointer disabled:cursor-not-allowed disabled:opacity-40",
      accent_classes(color)
    ]
  end

  defp accent_classes("primary"), do: "accent-pp-primary"
  defp accent_classes("secondary"), do: "accent-pp-secondary"
  defp accent_classes("tertiary"), do: "accent-pp-tertiary"
  defp accent_classes("error"), do: "accent-pp-error"
end
