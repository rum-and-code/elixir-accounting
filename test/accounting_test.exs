defmodule AccountingTest do
  use Accounting.RepoCase

  alias Accounting.{Account, Entry, Transaction}

  doctest Accounting

  setup do
    cash_account = create_account("cash", :debit)
    sales_account = create_account("sales", :credit)

    account_attrs = %{
      type: :debit,
      identifier: "inventory",
      description: "inventory"
    }

    %{
      cash_account: cash_account,
      sales_account: sales_account,
      account_attrs: account_attrs
    }
  end

  describe("Accounting.create_account/1") do
    test("it can create an account", %{account_attrs: account_attrs}) do
      assert {:ok, %Account{}} = Accounting.create_account(account_attrs)
    end

    test("it does nothing if account has same identifier as existing one", %{account_attrs: account_attrs}) do
      assert {:ok, %Account{id: id}} = Accounting.create_account(account_attrs)
      refute is_nil(id)

      assert {:ok, %Account{id: nil}} = Accounting.create_account(account_attrs)
    end
  end

  describe("Accounting.get_or_create_account/1") do
    test("it creates and returns the account if it does not exist", %{account_attrs: account_attrs}) do
      assert {:ok, %Account{}} = Accounting.get_or_create_account(account_attrs)
    end

    test("it returns the account if an account with the same identifier already exists", %{account_attrs: account_attrs}) do
      assert {:ok, %Account{id: id}} = Accounting.get_or_create_account(account_attrs)
      refute is_nil(id)
      assert {:ok, %Account{id: ^id}} = Accounting.get_or_create_account(account_attrs)
    end
  end

  describe("Accounting.get_account_by_identifier/1") do
    test("it returns the account if it exists", %{account_attrs: account_attrs}) do
      {:ok, %Account{id: id}} = Accounting.create_account(account_attrs)

      identifier = account_attrs.identifier
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

      assert {:ok, %Transaction{}} = Accounting.create_transaction(attrs)
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
        assert {:error, %Ecto.Changeset{errors: errors}} =
                 Accounting.create_transaction(Map.put(attrs, :entries, invalid_entry))

        assert {"must have at least 2 balanced entries", _} = Keyword.get(errors, :entries)
      end)
    end
  end

  describe("Accounting.account_balance/2") do
    test("an account with no transactions has a balance of 0", context) do
      assert {:ok, amount} = Accounting.account_balance(context.cash_account.id)
      assert amount == Decimal.new(0)
    end

    test("it calculates the balance of an account", context) do
      amounts = [100, 50, 25]

      Enum.each(amounts, fn amount ->
        create_transaction(context, amount, amount)
      end)

      assert {:ok, cash_balance} = Accounting.account_balance(context.cash_account.id)
      assert {:ok, sales_balance} = Accounting.account_balance(context.sales_account.id)

      assert cash_balance == Decimal.new(Enum.sum(amounts))
      assert sales_balance == Decimal.new(Enum.sum(amounts))
    end

    test("it accepts a query to filter entries by date", context) do
      seconds_in_a_day = 60 * 60 * 24

      today = NaiveDateTime.utc_now()
      tomorrow = NaiveDateTime.add(NaiveDateTime.utc_now(), seconds_in_a_day, :second)
      after_tomorrow = NaiveDateTime.add(NaiveDateTime.utc_now(), 2 * seconds_in_a_day, :second)

      amounts_by_date = %{
        today => 100,
        tomorrow => 50,
        after_tomorrow => 25
      }

      Enum.each(amounts_by_date, fn {date, amount} ->
        create_transaction(context, amount, amount, date)
      end)

      query =
        from(
          e in Entry,
          join: t in assoc(e, :transaction),
          where: t.date >= ^tomorrow
        )

      assert {:ok, amount} = Accounting.account_balance(context.sales_account.id, query)
      assert amount == Decimal.new(75)
    end
  end

  defp create_account(identifier, type) do
    {:ok, account} =
      Accounting.create_account(%{
        identifier: identifier,
        description: identifier,
        type: type
      })

    account
  end

  defp create_transaction(context, cash_amount, sales_amount, date \\ NaiveDateTime.utc_now()) do
    attrs = %{
      date: date,
      description: "test transaction",
      entries: [
        %{account_id: context.cash_account.id, type: :debit, amount: cash_amount},
        %{account_id: context.sales_account.id, type: :credit, amount: sales_amount}
      ]
    }

    {:ok, %Transaction{} = transaction} = Accounting.create_transaction(attrs)

    transaction
  end
end
