defmodule Accounting.Repo do
  use Ecto.Repo,
    otp_app: :accounting,
    adapter: Ecto.Adapters.Postgres
end
