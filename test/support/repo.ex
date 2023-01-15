defmodule Accounting.TestSupport.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :accounting,
    adapter: Ecto.Adapters.Postgres

  def log(_cmd), do: nil
end
