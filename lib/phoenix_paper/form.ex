defmodule PhoenixPaper.Form do
  @moduledoc """
  A thin Material layout around Phoenix's own `Phoenix.Component.form/1`
  (`pp_form/1`): the same `for`/`as`/`action`/`:let` API, plus consistent
  vertical spacing between fields and an `:actions` row for the submit/
  cancel buttons.

      <.pp_form for={@form} phx-change="validate" phx-submit="save">
        <.pp_input field={@form[:email]} type="email" label="Email" />
        <.pp_input field={@form[:name]} label="Name" />
        <:actions>
          <.pp_button variant="text" patch={~p"/users"}>Cancel</.pp_button>
          <.pp_button type="submit">Save</.pp_button>
        </:actions>
      </.pp_form>

  Everything that makes a form work (CSRF token, `_method` input for
  `action` + `method`, `multipart`, `errors`, the `:let` form) is
  `Phoenix.Component.form/1`'s, called underneath, so plain `<.form>` keeps
  working too: every `pp_*` form control takes `field=` either way. Reach for
  `pp_form/1` when you want the spacing and actions row without writing them
  by hand.

  ## Layout

  The form is a column with `spacing` between its children (a
  `PhoenixPaper.Spacing` token, default `:md` = `gap-4`, like
  `PhoenixPaper.Stack`; change it with the attr, not a `gap-*` class).
  `:actions` renders last, right-aligned, Material's placement for form and
  dialog actions. `paperize={false}` drops the column and gap; the actions
  row keeps its `flex` layout since it has no `class` of its own to rebuild
  it with (the same exception `AppBar`'s toolbar row makes).
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Spacing}

  attr(:for, :any, required: true, doc: "the form source, usually from to_form/2")
  attr(:as, :any, default: nil, doc: "the server-side parameter name the data is collected under")
  attr(:action, :string, default: nil, doc: "the action to submit to; omit in LiveView")
  attr(:method, :string, default: nil, doc: "the HTTP method, used only with action")
  attr(:multipart, :boolean, default: false, doc: "sets enctype to multipart/form-data")
  attr(:csrf_token, :any, default: nil)
  attr(:errors, :list, default: nil)
  attr(:spacing, :atom, default: :md, values: ~w(none xs sm md lg xl 2xl)a)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include: ~w(autocomplete name rel enctype novalidate target),
    doc: "phx-change, phx-submit, id, ... pass through to the <form>"
  )

  slot(:inner_block, required: true, doc: "the fields; receives the form via :let")
  slot(:actions, doc: "submit/cancel buttons, rendered right-aligned after the fields")

  @doc "Renders a form. See the module doc."
  def pp_form(assigns) do
    # `Phoenix.Component.form/1` reads `as`/`method`/`errors`/`csrf_token`
    # straight out of its assigns, so a `nil` would be passed on as an
    # explicit option rather than "not given"; only forward what was set.
    form_attrs =
      assigns
      |> Map.take([:for, :as, :action, :method, :csrf_token, :errors])
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
      |> Map.put(:multipart, assigns.multipart)
      |> Map.merge(assigns.rest)
      |> Map.put(
        :class,
        Helpers.classes(assigns.paperize, paper_classes(assigns.spacing), assigns.class)
      )
      |> Map.put(:"data-pp-component", "form")

    assigns = assign(assigns, :form_attrs, form_attrs)

    ~H"""
    <.form :let={f} {@form_attrs}>
      {render_slot(@inner_block, f)}
      <div :if={@actions != []} class="flex flex-wrap items-center justify-end gap-2">
        {render_slot(@actions, f)}
      </div>
    </.form>
    """
  end

  defp paper_classes(spacing), do: ["flex flex-col", Spacing.gap(spacing)]
end
