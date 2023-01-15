import Config

config :accounting, :ecto_repos, [Accounting.Repo]

config :accounting, Accounting.Repo,
  database: "accounting_#{config_env()}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
