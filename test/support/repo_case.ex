defmodule Accounting.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Accounting.Repo

      import Ecto
      import Ecto.Query
      import Accounting.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Accounting.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Accounting.Repo, {:shared, self()})
    end

    :ok
  end
end
