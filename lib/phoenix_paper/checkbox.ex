defmodule PhoenixPaper.Checkbox do
  @moduledoc """
  A Material Design checkbox (`pp_checkbox/1`).

  Accepts either a Phoenix `Phoenix.HTML.FormField` via `field=` (idiomatic
  `to_form/2` usage, same as the default `core_components.ex` input) or plain
  `name`/`checked` attrs.

  When `paperize` is `false` this renders a bare native `<input
  type="checkbox">` (no hidden-input trick, no custom box) so it never fights
  a caller's own CSS.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Shape}

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: "true")
  attr(:label, :string, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:checked, :boolean, default: nil)
  attr(:paperize, :boolean, default: true)
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form autofocus phx-click))

  def pp_checkbox(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:id, fn -> field.id end)
    |> assign_new(:checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", field.value) end)
    |> pp_checkbox()
  end

  def pp_checkbox(assigns) do
    assigns = assign_new(assigns, :checked, fn -> false end)

    ~H"""
    <label data-pp-component="checkbox" class={Helpers.classes(@paperize, "inline-flex items-center gap-2 cursor-pointer select-none", @class)}>
      <input :if={@paperize} type="hidden" name={@name} value="false" disabled={@disabled} />

      <span :if={@paperize} class={[
        "has-[:checked]:border-pp-primary has-[:checked]:bg-pp-primary relative inline-flex size-5 shrink-0 items-center justify-center border-2 border-pp-outline transition-colors",
        Shape.class(:xs)
      ]}>
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value={@value}
          checked={@checked}
          disabled={@disabled}
          class="peer absolute inset-0 m-0 cursor-pointer opacity-0 disabled:cursor-not-allowed"
          {@rest}
        />
        <span class="pp-checkbox-check pointer-events-none opacity-0 peer-checked:opacity-100 text-pp-on-primary text-xs">
          {"✓"}
        </span>
      </span>

      <input
        :if={!@paperize}
        type="checkbox"
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        disabled={@disabled}
        {@rest}
      />

      <span :if={@label}>{@label}</span>
    </label>
    """
  end
end
