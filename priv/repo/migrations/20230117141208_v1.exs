defmodule Accounting.TestSupport.Repo.Migrations.V1 do
  use Ecto.Migration

  def change do
    Accounting.Migrations.V1.change()
  end
end
