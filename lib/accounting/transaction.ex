defmodule Accounting.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting_transactions" do
    field(:date, :naive_datetime)
    field(:description, :string)

    has_many(:entries, Accounting.Entry)

    timestamps()
  end

  def changeset(attrs) do
    %Accounting.Transaction{}
    |> cast(attrs, [:date, :description])
    |> cast_assoc(:entries)
    |> validate_entries()
  end

  defp validate_entries(changeset) do
    {_, entries} = fetch_field(changeset, :entries)

    %{debit: debit, credit: credit} =
      entries
      |> Enum.group_by(& &1.type)
      |> Enum.into(%{}, fn {type, entries} ->
        total = entries |> Enum.map(& &1.amount) |> Enum.reduce(&Decimal.add/2)
        {type, total}
      end)

    if Decimal.equal?(debit, credit) do
      changeset
    else
      add_error(changeset, :entries, "Entries must balance")
    end
  end
end
