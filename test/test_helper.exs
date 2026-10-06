Logger.configure(level: :warning)

Application.put_env(:phoenix_paper, PhoenixPaper.TestEndpoint,
  secret_key_base: String.duplicate("phoenix_paper", 6),
  live_view: [signing_salt: "phoenix_paper_salt"],
  # LiveViewTest's uploads (PhoenixPaper.Upload's tests) join a channel,
  # which subscribes through the endpoint's PubSub.
  pubsub_server: PhoenixPaper.TestPubSub
)

{:ok, _} = Phoenix.PubSub.Supervisor.start_link(name: PhoenixPaper.TestPubSub)
{:ok, _} = PhoenixPaper.TestEndpoint.start_link()

ExUnit.start()
