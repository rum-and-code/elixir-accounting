defmodule Accounting.Migrations.V1 do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:accounting_accounts) do
      add(:type, :string)
      add(:identifier, :string)
      add(:description, :text)

      timestamps()
    end

    create(unique_index(:accounting_accounts, [:identifier]))

    create table(:accounting_transactions) do
      add(:date, :naive_datetime)
      add(:description, :text)

      timestamps()
    end

    create table(:accounting_entries) do
      add(:transaction_id, references(:accounting_transactions))
      add(:account_id, references(:accounting_accounts))

      add(:description, :text)
      add(:type, :string)
      add(:amount, :decimal)

      timestamps()
    end
  end
end
