defmodule Accounting.Account do
  use Ecto.Schema
  import Ecto.Changeset

  alias Accounting.Account

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
end
