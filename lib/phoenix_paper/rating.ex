defmodule PhoenixPaper.Rating do
  @moduledoc """
  A Material Design star rating (`pp_rating/1`). Interactive by default (a
  row of radio inputs with a pure-CSS hover/checked fill effect, no JS);
  pass `readonly` to render a fixed display of `value` filled stars instead.

  The fill effect (hovering/checking star N highlights stars 1..N) relies on
  the classic flat-sibling radio+label CSS trick — each `<input>` and its
  `<label>` must be direct siblings of every other star's, not nested inside
  a wrapping element per star, or the `~` sibling selectors can't reach
  across stars. Because of that, `paperize={false}` here loses the
  `flex-row-reverse` layout too, not just colors — the caller takes over
  layout entirely, same as any other component's contract, but it's worth
  calling out since a plain `<div>` won't reproduce the fill effect on its
  own without that layout.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :integer, default: 0)
  attr(:max, :integer, default: 5)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:readonly, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form))

  def pp_rating(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:id, fn -> field.id end)
    |> assign_new(:value, fn -> normalize_value(field.value) end)
    |> pp_rating()
  end

  def pp_rating(assigns) do
    assigns = assign(assigns, :base_id, assigns.id || assigns.name)

    ~H"""
    <div
      data-pp-component="rating"
      class={Helpers.classes(@paperize, "inline-flex flex-row-reverse items-center gap-1", @class)}
      {@rest}
    >
      <%= for n <- @max..1//-1 do %>
        <input
          :if={!@readonly}
          type="radio"
          id={"#{@base_id}-star-#{n}"}
          name={@name}
          value={n}
          checked={@value == n}
          disabled={@disabled}
          class="peer sr-only"
        />
        <label
          :if={!@readonly}
          for={"#{@base_id}-star-#{n}"}
          class={Helpers.classes(@paperize, star_classes(), nil)}
        >
          {"★"}
        </label>
        <span :if={@readonly} class={Helpers.classes(@paperize, readonly_star_classes(n <= @value), nil)}>
          {"★"}
        </span>
      <% end %>
    </div>
    """
  end

  defp star_classes do
    "peer-checked:text-pp-secondary peer-hover:text-pp-secondary hover:text-pp-secondary cursor-pointer text-xl text-pp-outline transition-colors"
  end

  defp readonly_star_classes(true), do: "text-xl text-pp-secondary"
  defp readonly_star_classes(false), do: "text-xl text-pp-outline"

  defp normalize_value(v) when is_integer(v), do: v
  defp normalize_value(v) when is_binary(v), do: String.to_integer(v)
  defp normalize_value(_), do: 0
end
