defmodule Accounting.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting_entries" do
    belongs_to(:transaction, Accounting.Transaction)
    belongs_to(:account, Accounting.Account)

    field(:description, :string)
    field(:type, Ecto.Enum, values: [:debit, :credit])
    field(:amount, :decimal)

    timestamps()
  end

  @required ~w(
    account_id
    type
    amount
  )a

  @optional ~w(
    description
  )a
  def changeset(entry \\ %Accounting.Entry{}, attrs) do
    entry
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_number(:amount, greater_than: 0)
  end
end
