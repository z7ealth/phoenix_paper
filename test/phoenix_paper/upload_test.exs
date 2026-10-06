defmodule PhoenixPaper.UploadTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  @endpoint PhoenixPaper.TestEndpoint

  defmodule Host do
    use Phoenix.LiveView

    def mount(_params, _session, socket) do
      {:ok,
       allow_upload(socket, :photos, accept: ~w(.png .jpg), max_entries: 2, max_file_size: 1_000)}
    end

    def render(assigns) do
      ~H"""
      <form id="upload-form" phx-change="validate" phx-submit="save">
        <PhoenixPaper.Upload.pp_upload
          upload={@uploads.photos}
          on_cancel="cancel"
          supporting_text="PNG or JPG"
        />
      </form>
      """
    end

    def handle_event("validate", _params, socket), do: {:noreply, socket}

    def handle_event("cancel", %{"ref" => ref}, socket),
      do: {:noreply, cancel_upload(socket, :photos, ref)}
  end

  defp mount_upload do
    {:ok, view, html} = live_isolated(Phoenix.ConnTest.build_conn(), Host)
    {view, html}
  end

  test "renders the MD3 drop zone wired to LiveView's file input" do
    {_view, html} = mount_upload()

    assert html =~ ~s(data-pp-component="upload")
    assert html =~ "phx-drop-target="
    assert html =~ "bg-pp-surface-container-low"
    assert html =~ "border-pp-outline-variant"
    assert html =~ "[&amp;.phx-drop-target-active]:border-pp-primary"
    assert html =~ "Drag files here"
    assert html =~ "PNG or JPG"
    assert html =~ "Browse files"
    assert html =~ ~s(type="file")
    assert html =~ ~s(accept=".png,.jpg")
    assert html =~ "document.getElementById("
  end

  test "a selected file gets a row with a progress indicator and a cancel button" do
    {view, _} = mount_upload()

    input =
      file_input(view, "#upload-form", :photos, [
        %{name: "cat.png", content: "0123456789", type: "image/png"}
      ])

    html = render_upload(input, "cat.png", 40)

    assert html =~ ~s(data-pp-component="upload-entry")
    assert html =~ "cat.png"
    assert html =~ ~s(role="progressbar" aria-label="cat.png 40%")
    assert html =~ ~s(aria-label="Cancel cat.png")
    assert html =~ ~s(phx-value-ref=)
  end

  test "cancelling removes the row" do
    {view, _} = mount_upload()

    input =
      file_input(view, "#upload-form", :photos, [
        %{name: "cat.png", content: "0123456789", type: "image/png"}
      ])

    render_upload(input, "cat.png", 10)

    view |> element("[aria-label='Cancel cat.png']") |> render_click()

    # An in-progress entry is dropped when its upload channel exits, just
    # after the click's own reply, so check the next render.
    refute render(view) =~ ~s(data-pp-component="upload-entry")
  end

  test "a rejected file shows its error, in MD3 error color" do
    {view, _} = mount_upload()

    input =
      file_input(view, "#upload-form", :photos, [
        %{name: "big.png", content: String.duplicate("x", 2_000), type: "image/png"}
      ])

    assert {:error, _} = render_upload(input, "big.png")

    html = render(view)
    assert html =~ "File is too large"
    assert html =~ "text-pp-error"
  end

  test "error_to_string translates errors" do
    html =
      render_component(&PhoenixPaper.Upload.pp_upload/1,
        upload: %Phoenix.LiveView.UploadConfig{
          ref: "phx-ref",
          name: :photos,
          accept: :any,
          entries: [],
          errors: [{"phx-ref", :too_many_files}]
        },
        error_to_string: fn :too_many_files -> "Demasiados archivos" end
      )

    assert html =~ "Demasiados archivos"
  end

  test "paperize false drops the skin" do
    html =
      render_component(&PhoenixPaper.Upload.pp_upload/1,
        upload: %Phoenix.LiveView.UploadConfig{ref: "r", name: :photos, accept: :any, entries: []},
        paperize: false,
        class: "mine"
      )

    assert html =~ "mine"
    refute html =~ "bg-pp-surface-container-low"
    assert html =~ ~s(type="file")
  end
end
