defmodule Accounting.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting_transactions" do
    field(:date, :naive_datetime)
    field(:description, :string)

    has_many(:entries, Accounting.Entry)

    timestamps()
  end

  @required ~w(
    date
    description
  )a

  def changeset(attrs) do
    %Accounting.Transaction{}
    |> cast(attrs, @required)
    |> cast_assoc(:entries)
    |> validate_required(@required)
    |> validate_entries()
  end

  defp validate_entries(changeset) do
    {_, entries} = fetch_field(changeset, :entries)

    sums_by_type =
      entries
      |> Enum.group_by(& &1.type)
      |> Enum.into(%{}, fn {type, entries} ->
        total = entries |> Enum.map(& &1.amount) |> Enum.reduce(&Decimal.add/2)
        {type, total}
      end)

    with %{debit: debit, credit: credit} <- sums_by_type,
         true <- Decimal.equal?(debit, credit) do
      changeset
    else
      _ -> add_error(changeset, :entries, "must have at least 2 balanced entries")
    end
  end
end
