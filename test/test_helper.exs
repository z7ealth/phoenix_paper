Logger.configure(level: :warning)

Application.put_env(:phoenix_paper, PhoenixPaper.TestEndpoint,
  secret_key_base: String.duplicate("phoenix_paper", 6),
  live_view: [signing_salt: "phoenix_paper_salt"]
)

{:ok, _} = PhoenixPaper.TestEndpoint.start_link()

ExUnit.start()
