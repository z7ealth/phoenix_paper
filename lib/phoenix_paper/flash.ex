defmodule PhoenixPaper.Flash do
  @moduledoc """
  Renders Phoenix's flash messages (`@flash`) as MD3 snackbars
  (`pp_flash_group/1`) — the Material counterpart of the `flash_group/1` in
  a freshly generated `core_components.ex`.

      <.pp_flash_group flash={@flash} />

  Drop it once in your root layout (or app layout), the same place the
  generated `<.flash_group>` goes. It reads `:info` and `:error` out of
  the flash and shows one `PhoenixPaper.Snackbar` per present message,
  stacked where MD3 puts snackbars (bottom center on compact screens,
  bottom-start from `sm` up):

  - **Dismiss** is wired to LiveView's built-in `lv:clear-flash` client
    event (`Phoenix.LiveView.JS.push("lv:clear-flash", value: %{key: kind})`)
    — no handler in your LiveView. Clicking a snackbar's close button
    clears that key; the server re-renders without it and it's gone.
  - **Auto-dismiss** is opt-in: `auto_hide_duration={4000}` makes each
    snackbar clear itself after 4s via the same `lv:clear-flash`, using
    `PhoenixPaper.Snackbar`'s hook-free CSS-animation timer.

  `pp_snackbar` positions itself; a *group* needs to read the flash map,
  key each dismiss to the right flash key and stack several without them
  overlapping, so `pp_flash_group` owns the `fixed` stack and each
  snackbar inside is a `pp_snackbar positioned={false}`.

  `kinds` changes or extends the keys rendered
  (`kinds={[:info, :warning, :error]}`). MD3 snackbars are text-only and
  look the same whatever the message, so the kind only sets the ARIA role
  (`alert` for `:error`, `status` otherwise).

  ## Connection-lost notices

  `connection_notices` also renders the two "connection lost" messages a
  generated `core_components.ex` `flash_group/1` shows:

      <.pp_flash_group flash={@flash} connection_notices />

  They aren't flash messages (the server is exactly what's unreachable).
  Both snackbars are rendered `hidden` and toggled client-side:
  `phx-disconnected` removes `hidden` and `phx-connected` puts it back,
  scoped to the LiveView container's `.phx-client-error` /
  `.phx-server-error` class, the way the generated component does it.
  `client_error_title`/`server_error_title` and `reconnecting_text`
  override the English defaults (e.g. with `gettext`).

  ## Migrating from 0.4

  `anchor_origin` and `transition` are gone (snackbars sit at the bottom,
  with MD3's one entrance), and messages no longer get a leading icon.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import PhoenixPaper.Snackbar, only: [pp_snackbar: 1]

  attr(:flash, :map, required: true, doc: "the @flash map from the assigns")

  attr(:kinds, :list,
    default: [:info, :error],
    doc: "flash keys to render, in stacking order"
  )

  attr(:auto_hide_duration, :integer,
    default: nil,
    doc: "milliseconds after which each chip clears itself via lv:clear-flash (opt-in)"
  )

  attr(:connection_notices, :boolean,
    default: false,
    doc: "also render the hidden client/server connection-lost chips (see the module doc)"
  )

  attr(:client_error_title, :string, default: "We can't find the internet")
  attr(:server_error_title, :string, default: "Something went wrong!")
  attr(:reconnecting_text, :string, default: "Attempting to reconnect")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders every present flash message as a stacked snackbar. See the module doc."
  def pp_flash_group(assigns) do
    ~H"""
    <div
      data-pp-component="flash-group"
      class={[@paperize && stack_classes(), @class]}
      {@rest}
    >
      <.pp_flash
        :for={kind <- @kinds}
        kind={kind}
        flash={@flash}
        auto_hide_duration={@auto_hide_duration}
        paperize={@paperize}
      />
      <.connection_notice
        :if={@connection_notices}
        id="pp-flash-client-error"
        error_class="phx-client-error"
        title={@client_error_title}
        text={@reconnecting_text}
        paperize={@paperize}
      />
      <.connection_notice
        :if={@connection_notices}
        id="pp-flash-server-error"
        error_class="phx-server-error"
        title={@server_error_title}
        text={@reconnecting_text}
        paperize={@paperize}
      />
    </div>
    """
  end

  defp connection_notice(assigns) do
    ~H"""
    <.pp_snackbar
      id={@id}
      role="alert"
      positioned={false}
      paperize={@paperize}
      hidden
      phx-disconnected={JS.remove_attribute("hidden", to: ".#{@error_class} ##{@id}")}
      phx-connected={JS.set_attribute({"hidden", ""}, to: "##{@id}")}
    >
      <span class="block">{@title}</span>
      <span class="block">{@text}</span>
    </.pp_snackbar>
    """
  end

  attr(:kind, :atom, required: true)
  attr(:flash, :map, required: true)
  attr(:auto_hide_duration, :integer, default: nil)
  attr(:paperize, :boolean, default: true)

  @doc "Renders one flash key as a snackbar, or nothing when that key is empty."
  def pp_flash(assigns) do
    assigns = assign(assigns, :message, Phoenix.Flash.get(assigns.flash, assigns.kind))

    ~H"""
    <.pp_snackbar
      :if={@message}
      id={"pp-flash-#{@kind}"}
      role={if @kind == :error, do: "alert", else: "status"}
      positioned={false}
      auto_hide_duration={@auto_hide_duration}
      on_close={JS.push("lv:clear-flash", value: %{key: to_string(@kind)})}
      paperize={@paperize}
    >
      {@message}
    </.pp_snackbar>
    """
  end

  defp stack_classes do
    "pointer-events-none fixed inset-x-4 bottom-4 z-50 flex flex-col items-center gap-2 sm:inset-x-auto sm:start-6 sm:bottom-6 sm:items-start [&_[data-pp-component=snackbar]]:pointer-events-auto"
  end
end
