defmodule PhoenixPaper.Switch do
  @moduledoc """
  A Material Design switch (`pp_switch/1`) — an on/off toggle, structured
  like `PhoenixPaper.Checkbox` but rendered as a sliding track/thumb.

  Accepts either a Phoenix `Phoenix.HTML.FormField` via `field=` or plain
  `name`/`checked` attrs.

  When `paperize` is `false` this renders a bare native `<input
  type="checkbox">` (no hidden-input trick, no custom track/thumb) —
  `class` targets that bare input directly in this case, same as
  `PhoenixPaper.Checkbox`.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple}

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: "true")
  attr(:label, :string, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:checked, :boolean, default: nil)
  attr(:paperize, :boolean, default: true)

  attr(:ripple, :boolean,
    default: true,
    doc:
      "the Material ripple effect on click/tap — off whenever paperize is false, see PhoenixPaper.Ripple"
  )

  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form autofocus phx-click))

  def pp_switch(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:name, assigns.name || field.name)
    |> assign(:id, assigns.id || field.id)
    |> assign(
      :checked,
      if(is_nil(assigns.checked),
        do: Phoenix.HTML.Form.normalize_value("checkbox", field.value),
        else: assigns.checked
      )
    )
    |> pp_switch()
  end

  def pp_switch(assigns) do
    assigns =
      assigns
      |> assign(:checked, assigns.checked || false)
      |> assign(:ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <label data-pp-component="switch" class={Helpers.toggle_label_classes(if @paperize, do: @class)}>
      <input :if={@paperize} type="hidden" name={@name} value="false" disabled={@disabled} />

      <span
        :if={@paperize}
        class="has-[:checked]:bg-pp-primary/50 has-[:disabled]:opacity-40 relative inline-flex h-6 w-10 shrink-0 items-center rounded-full bg-pp-outline/40 transition-colors"
        onclick={Ripple.on_click_centered(@ripple?)}
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
        class={@class}
        {@rest}
      />

      <span :if={@label}>{@label}</span>
    </label>
    """
  end
end
