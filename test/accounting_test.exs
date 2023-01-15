defmodule AccountingTest do
  use Accounting.RepoCase

  alias Accounting.Account

  doctest Accounting

  @attrs %{
    type: :debit,
    identifier: "cash",
    description: "cash on hand"
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
      assert {:error, :not_found} = Accounting.get_account_by_identifier("sales")
    end
  end
end
