defmodule Accounting.Account do
  use Ecto.Schema
  import Ecto.Changeset

  alias Accounting.{Account, Entry}

  schema "accounting_accounts" do
    field(:type, Ecto.Enum, values: [:debit, :credit])
    field(:identifier, :string)
    field(:description, :string)

    timestamps()
  end

  @required [:type, :identifier, :description]
  def changeset(attrs) do
    %Account{}
    |> cast(attrs, @required)
    |> validate_length(:identifier, max: 255)
    |> validate_required(@required)
  end

  def entry_amount(%Account{type: type}, %Entry{type: type, amount: amount}), do: amount
  def entry_amount(_, %Entry{amount: amount}), do: %{amount | sign: -1}
end
