import Config

config :accounting, ecto_repos: [Accounting.TestSupport.Repo]

config :accounting, Accounting.TestSupport.Repo,
  database: "accounting_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  log: false
