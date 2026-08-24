defmodule PhoenixPaper.Switch do
  @moduledoc """
  A Material Design switch (`pp_switch/1`) — an on/off toggle, structured
  like `PhoenixPaper.Checkbox` but rendered as a sliding track/thumb.

  Accepts either a Phoenix `Phoenix.HTML.FormField` via `field=` or plain
  `name`/`checked` attrs.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

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

  def pp_switch(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:id, fn -> field.id end)
    |> assign_new(:checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", field.value) end)
    |> pp_switch()
  end

  def pp_switch(assigns) do
    assigns = assign_new(assigns, :checked, fn -> false end)

    ~H"""
    <label
      data-pp-component="switch"
      class={Helpers.classes(@paperize, "inline-flex items-center gap-2 cursor-pointer select-none", @class)}
    >
      <input :if={@paperize} type="hidden" name={@name} value="false" disabled={@disabled} />

      <span
        :if={@paperize}
        class="has-[:checked]:bg-pp-primary/50 has-[:disabled]:opacity-40 relative inline-flex h-6 w-10 shrink-0 items-center rounded-full bg-pp-outline/40 transition-colors"
      >
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
        <span class="peer-checked:translate-x-4 peer-checked:bg-pp-primary pointer-events-none absolute left-0.5 size-5 rounded-full bg-white shadow transition-transform" />
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
