{:ok, _pid} = Accounting.TestSupport.Repo.start_link()
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Accounting.TestSupport.Repo, :manual)
