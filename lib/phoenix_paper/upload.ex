defmodule PhoenixPaper.Upload do
  @moduledoc """
  A file upload (`pp_upload/1`) for LiveView uploads: a drop zone with a
  browse button, and one row per selected file with its preview,
  progress, errors and a cancel button.

      # mount/3
      socket |> allow_upload(:photos, accept: ~w(.jpg .png), max_entries: 3)

      # template, inside a form with phx-change and phx-submit
      <.pp_upload upload={@uploads.photos} on_cancel="cancel_upload" supporting_text="JPG or PNG, up to 8 MB" />

      def handle_event("cancel_upload", %{"ref" => ref}, socket),
        do: {:noreply, cancel_upload(socket, :photos, ref)}

  MD3 has no upload component; this is the Phoenix-needs exception (like
  `PhoenixPaper.Flash`), built only from MD3 parts around Phoenix's own
  `live_file_input/1`:

  - **The drop zone** is a `surface-container-low` area with an
    `outline-variant` border and medium (12dp) corners, holding an icon,
    `label` (`body-large`) and a tonal `pp_button` that opens the file
    picker. While files are dragged over it (LiveView adds
    `phx-drop-target-active`), it shows MD3's dragged state: a 16% state
    layer and a `primary` outline.
  - **Each file** is an MD3 list-item-like row: an image preview
    (`live_img_preview/1`, 40dp, small corners) or a document icon, the
    name (`body-large`), a linear `pp_progress` while uploading, its
    errors in `error`, and a trailing `pp_icon_button` that sends
    `on_cancel` with the entry's `ref` (`phx-value-ref`; `target` sets
    `phx-target`). Without `on_cancel` there's no cancel button.
  - **Errors** — the upload's own (too many files) under the drop zone,
    each file's under its name — are mapped to English text
    (`too_large`, `too_many_files`, `not_accepted`,
    `external_client_failure`); pass `error_to_string` (a function from
    the error to text) to translate them or handle your own.

  The drop zone needs `phx-drop-target`, which LiveView only wires inside
  a LiveView, and the input needs to be inside a form with `phx-change`
  (LiveView's upload requirement).

  `label` (default `"Drag files here"`), `browse_label` (`"Browse
  files"`), `cancel_label` (`"Cancel"`) and `preview` (default `true`)
  can be changed.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.Button, only: [pp_button: 1]
  import PhoenixPaper.Icon, only: [pp_icon: 1]
  import PhoenixPaper.IconButton, only: [pp_icon_button: 1]
  import PhoenixPaper.Progress, only: [pp_progress: 1]

  attr(:upload, Phoenix.LiveView.UploadConfig,
    required: true,
    doc: "the upload, e.g. @uploads.photos"
  )

  attr(:label, :string, default: "Drag files here")
  attr(:browse_label, :string, default: "Browse files")
  attr(:supporting_text, :string, default: nil, doc: "a hint under the label, e.g. size limits")

  attr(:on_cancel, :any,
    default: nil,
    doc: "event (or JS) for each file's cancel button; sends phx-value-ref"
  )

  attr(:target, :any, default: nil, doc: "phx-target for on_cancel")
  attr(:cancel_label, :string, default: "Cancel")
  attr(:preview, :boolean, default: true, doc: "show image previews")

  attr(:error_to_string, :any,
    default: nil,
    doc: "a function from an upload error to text; defaults to English messages"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders a file upload. See the module doc."
  def pp_upload(assigns) do
    ~H"""
    <div
      data-pp-component="upload"
      class={Helpers.classes(@paperize, "flex flex-col gap-2", @class)}
      {@rest}
    >
      <div
        phx-drop-target={@upload.ref}
        class={Helpers.classes(@paperize, zone_classes(), nil)}
      >
        <.pp_icon
          name="hero-arrow-up-tray"
          size="lg"
          class={Helpers.classes(@paperize, "text-pp-on-surface-variant", nil)}
        />
        <p class={Helpers.classes(@paperize, "pp-body-large text-pp-on-surface", nil)}>{@label}</p>
        <p
          :if={@supporting_text}
          class={Helpers.classes(@paperize, "pp-body-small text-pp-on-surface-variant", nil)}
        >
          {@supporting_text}
        </p>
        <.pp_button
          type="button"
          variant="tonal"
          ripple={false}
          paperize={@paperize}
          onclick={"document.getElementById(#{inspect(@upload.ref)}).click()"}
        >
          {@browse_label}
        </.pp_button>
        <.live_file_input upload={@upload} class="sr-only" />
      </div>

      <p
        :for={error <- upload_errors(@upload)}
        class={Helpers.classes(@paperize, "px-4 pp-body-small text-pp-error", nil)}
      >
        {message(error, @error_to_string)}
      </p>

      <ul :if={@upload.entries != []} class="flex flex-col">
        <li
          :for={entry <- @upload.entries}
          data-pp-component="upload-entry"
          class={Helpers.classes(@paperize, "flex min-h-14 items-center gap-4 px-4 py-2", nil)}
        >
          <.live_img_preview
            :if={@preview && image?(entry)}
            entry={entry}
            class={Helpers.classes(@paperize, "size-10 shrink-0 rounded-pp-sm object-cover", nil)}
          />
          <.pp_icon
            :if={!(@preview && image?(entry))}
            name="hero-document"
            class={Helpers.classes(@paperize, "shrink-0 text-pp-on-surface-variant", nil)}
          />
          <div class="flex min-w-0 flex-1 flex-col gap-1">
            <span class={Helpers.classes(@paperize, "truncate pp-body-large text-pp-on-surface", nil)}>
              {entry.client_name}
            </span>
            <.pp_progress
              :if={entry.valid? and not entry.done?}
              value={entry.progress}
              label={"#{entry.client_name} #{entry.progress}%"}
              paperize={@paperize}
            />
            <span
              :for={error <- upload_errors(@upload, entry)}
              class={Helpers.classes(@paperize, "pp-body-small text-pp-error", nil)}
            >
              {message(error, @error_to_string)}
            </span>
          </div>
          <.pp_icon_button
            :if={@on_cancel}
            icon="hero-x-mark"
            label={"#{@cancel_label} #{entry.client_name}"}
            paperize={@paperize}
            phx-click={@on_cancel}
            phx-value-ref={entry.ref}
            phx-target={@target}
          />
        </li>
      </ul>
    </div>
    """
  end

  defp image?(%{client_type: "image/" <> _}), do: true
  defp image?(_entry), do: false

  defp message(error, fun) when is_function(fun, 1), do: fun.(error)
  defp message(:too_large, nil), do: "File is too large"
  defp message(:too_many_files, nil), do: "Too many files"
  defp message(:not_accepted, nil), do: "File type not accepted"
  defp message(:external_client_failure, nil), do: "Upload failed"
  defp message(error, nil), do: to_string(error)

  # MD3's dragged state is a 16% state layer; the outline turns primary.
  defp zone_classes do
    "flex flex-col items-center justify-center gap-3 rounded-pp-md border border-pp-outline-variant bg-pp-surface-container-low px-6 py-8 text-center pp-motion-effects-fast [&.phx-drop-target-active]:border-pp-primary [&.phx-drop-target-active]:bg-pp-primary/16"
  end
end
