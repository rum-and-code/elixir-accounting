defmodule Accounting.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Accounting.{Account, Entry}

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

  @doc """
  Returns the effective amount of the entry, for a given account.

  If the account type and entry type match, the amount is positive, otherwise
  it is negative.

  For example, a debit account with a debit entry will have a positive amount,
  while a debit account with a credit entry will have a negative amount.
  """
  def effective_amount(%Entry{type: type, amount: amount}, %Account{type: type}), do: amount
  def effective_amount(%Entry{amount: amount}, _), do: %{amount | sign: -1}
end
