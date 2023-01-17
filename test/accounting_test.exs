defmodule AccountingTest do
  use Accounting.RepoCase

  alias Accounting.Account

  doctest Accounting

  setup do
    cash_account = create_account("cash", :debit)
    sales_account = create_account("sales", :credit)

    %{
      cash_account: cash_account,
      sales_account: sales_account
    }
  end

  @attrs %{
    type: :debit,
    identifier: "inventory",
    description: "inventory"
  }

  describe("Accounting.create_account/1") do
    test("it can create an account") do
      assert {:ok, %Account{}} = Accounting.create_account(@attrs)
    end

    test("it does nothing if account has same identifier as existing one") do
      assert {:ok, %Account{id: id}} = Accounting.create_account(@attrs)
      refute is_nil(id)

      assert {:ok, %Account{id: nil}} = Accounting.create_account(@attrs)
    end
  end

  describe("Accounting.get_or_create_account/1") do
    test("it creates and returns the account if it does not exist") do
      assert {:ok, %Account{}} = Accounting.get_or_create_account(@attrs)
    end

    test("it returns the account if an account with the same identifier already exists") do
      assert {:ok, %Account{id: id}} = Accounting.get_or_create_account(@attrs)
      assert {:ok, %Account{id: ^id}} = Accounting.get_or_create_account(@attrs)
    end
  end

  describe("Accounting.get_account_by_identifier/1") do
    test("it returns the account if it exists") do
      {:ok, %Account{id: id}} = Accounting.create_account(@attrs)

      identifier = @attrs.identifier
      assert {:ok, %Account{id: ^id, identifier: ^identifier}} = Accounting.get_account_by_identifier(identifier)
    end

    test("it returns a not_found error if it does not exist") do
      assert {:error, :not_found} = Accounting.get_account_by_identifier("unexisting")
    end
  end

  describe("Accounting.create_transaction/1") do
    test("it can create a transaction", context) do
      attrs = %{
        date: NaiveDateTime.utc_now(),
        description: "test transaction",
        entries: [
          %{account_id: context.cash_account.id, type: :debit, amount: 100},
          %{account_id: context.sales_account.id, type: :credit, amount: 100}
        ]
      }

      assert {:ok, %Accounting.Transaction{}} = Accounting.create_transaction(attrs)
    end

    test("it does not create a transaction if required fields are empty", context) do
      attrs = %{
        date: NaiveDateTime.utc_now(),
        description: "a description",
        entries: [
          %{account_id: context.cash_account.id, type: :debit, amount: 100},
          %{account_id: context.sales_account.id, type: :credit, amount: 100}
        ]
      }

      assert {:error, %Ecto.Changeset{errors: errors}} = Accounting.create_transaction(Map.delete(attrs, :description))
      assert {"can't be blank", _} = Keyword.get(errors, :description)

      assert {:error, %Ecto.Changeset{errors: errors}} = Accounting.create_transaction(Map.delete(attrs, :date))
      assert {"can't be blank", _} = Keyword.get(errors, :date)
    end


    test("it does not create a transaction if the entries are not balanced", context) do
      attrs = %{
        date: NaiveDateTime.utc_now(),
        description: "unbalanced transaction",
        entries: [
          %{account_id: context.cash_account.id, type: :debit, amount: 100},
          %{account_id: context.sales_account.id, type: :credit, amount: 50}
        ]
      }

      assert {:error, %Ecto.Changeset{errors: errors}} = Accounting.create_transaction(attrs)
      assert {"must have at least 2 balanced entries", _} = Keyword.get(errors, :entries)
    end

    test("it does not create a transaction if the entries are invalid", context) do
      attrs = %{
        date: NaiveDateTime.utc_now(),
        description: "a description"
      }

      invalid_entries = [
        [],
        [
          %{account_id: context.cash_account.id, type: :debit, amount: 100},
          %{account_id: context.sales_account.id, type: :credit, amount: 50}
        ],
        [
          %{account_id: context.cash_account.id, type: :debit, amount: 100}
        ]
      ]

      Enum.each(invalid_entries, fn invalid_entry ->
        assert {:error, %Ecto.Changeset{errors: errors}} = Accounting.create_transaction(Map.put(attrs, :entries, invalid_entry))
        assert {"must have at least 2 balanced entries", _} = Keyword.get(errors, :entries)
      end)
    end
  end

  defp create_account(identifier, type) do
    {:ok, account} = Accounting.create_account(%{
      identifier: identifier,
      description: identifier,
      type: type
    })

    account
  end

end
