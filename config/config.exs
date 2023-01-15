import Config

config :application, :ecto_repos, []

import_config("#{config_env()}.exs")
