defmodule Accounting.Application do
  use Application

  def start(_type, _args) do
    children = [
      Accounting.Repo
    ]

    opts = [strategy: :one_for_one, name: Accounting.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
