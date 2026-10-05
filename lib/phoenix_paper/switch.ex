defmodule PhoenixPaper.Switch do
  @moduledoc """
  An MD3 switch (`pp_switch/1`) — an on/off toggle, structured like
  `PhoenixPaper.Checkbox` (a real checkbox underneath, a hidden input so
  "off" submits `"false"`).

      <.pp_switch field={@form[:notifications]} label="Notifications" />
      <.pp_switch name="wifi" label="Wi-Fi" icons checked />

  MD3 look: a 52×32 track — `surface-container-highest` with a 2dp
  `outline` border when off, solid `primary` when on — and a handle that
  **grows**: 16dp `outline` when off, 24dp `on-primary` when on, 28dp
  while pressed, sliding and resizing on the Expressive spatial spring. A
  40dp state layer sits behind the handle. `icons` puts a check (on) / ✕
  (off) inside the handle, which then stays 24dp in both states, per MD3.

  Under `paperize={false}` it's a bare native checkbox and `class`
  targets it, the same as `PhoenixPaper.Checkbox`.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: "true")
  attr(:label, :string, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:checked, :boolean, default: nil)
  attr(:icons, :boolean, default: false, doc: "check/x icons in the handle")
  attr(:paperize, :boolean, default: true)
  attr(:ripple, :boolean, default: false, doc: "the centered ripple on click")
  attr(:disabled, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form autofocus))

  @doc "Renders a switch. See the module doc."
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
        class="group/switch relative inline-flex h-8 w-[52px] shrink-0 items-center rounded-full border-2 border-pp-outline bg-pp-surface-container-highest pp-motion-effects-default has-[:checked]:border-pp-primary has-[:checked]:bg-pp-primary has-[:disabled]:opacity-38"
      >
        <input
          type="checkbox"
          role="switch"
          id={@id}
          name={@name}
          value={@value}
          checked={@checked}
          disabled={@disabled}
          class="peer absolute -inset-0.5 z-10 m-0 cursor-pointer opacity-0 disabled:cursor-default"
          {@rest}
        />
        <span
          class="absolute -start-1.5 top-1/2 inline-flex size-10 -translate-y-1/2 items-center justify-center pp-motion-spatial-fast peer-checked:translate-x-5"
          onclick={Ripple.on_click_centered(@ripple?)}
        >
          <span class="pp-state-layer-target absolute inset-0 rounded-full text-pp-on-surface group-has-[:checked]/switch:text-pp-primary" />
          <span class={handle_classes(@icons)}>
            <.pp_icon
              :if={@icons}
              name="hero-check"
              size="none"
              class="size-4 text-pp-on-primary-container group-has-[:not(:checked)]/switch:hidden"
            />
            <.pp_icon
              :if={@icons}
              name="hero-x-mark"
              size="none"
              class="size-4 text-pp-surface-container-highest group-has-[:checked]/switch:hidden"
            />
          </span>
        </span>
      </span>

      <input
        :if={!@paperize}
        type="checkbox"
        role="switch"
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        disabled={@disabled}
        class={@class}
        {@rest}
      />

      <span :if={@label} class={@paperize && "pp-body-large text-pp-on-surface"}>{@label}</span>
    </label>
    """
  end

  # Off: 16dp outline-colored (24dp with icons); on: 24dp on-primary; pressed:
  # 28dp. Hover darkens the handle (on-surface-variant off, primary-container
  # on), MD3's handle hover colors.
  defp handle_classes(false),
    do:
      "relative inline-flex size-4 items-center justify-center rounded-full bg-pp-outline pp-motion-spatial-fast group-hover/switch:bg-pp-on-surface-variant group-has-[:checked]/switch:size-6 group-has-[:checked]/switch:bg-pp-on-primary group-has-[:checked]/switch:group-hover/switch:bg-pp-primary-container group-active/switch:size-7"

  defp handle_classes(true),
    do:
      "relative inline-flex size-6 items-center justify-center rounded-full bg-pp-outline pp-motion-spatial-fast group-hover/switch:bg-pp-on-surface-variant group-has-[:checked]/switch:bg-pp-on-primary group-has-[:checked]/switch:group-hover/switch:bg-pp-primary-container group-active/switch:size-7"
end
