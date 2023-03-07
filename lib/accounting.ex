defmodule Accounting do
  @moduledoc """
  This library is a very basic implementation of a double-entry accounting system.

  Most of the ideas in here come from the
  [Accounting for Developers](https://www.moderntreasury.com/journal/accounting-for-developers-part-i)
  series. 
  You should definitely go ahead and read that before you go further.
  Everything will make more sense after that.

  It offers a simple structure, based on the 3 following models:

  - Account
  - Transaction
  - Entry

  An `Account` represents any balance that we might want to track in our system.
  For example, we might want to keep a customer's balance, or how much they spent in our store.
  We might want to split our sales in different categories, track inventory value, etc.

  A `Transaction` represents some movement of money from an account (or multiple accounts) 
  to another (or multiple others). 
  It is composed of at least 2 `Entry` (of types `:debit` or `:credit`).

  Credit and debit entries must always balance within a transaction.
  That means that if we were to subtract the total debit amounts from the total credit amounts, we
  would get 0.
  """

  import Ecto.Query

  alias Accounting.{Account, Entry, Transaction}

  def repo, do: List.first(Application.fetch_env!(:accounting, :ecto_repos))

  @doc """
  Creates an account with the given attributes.

  A conflict may occur if the identifier is already used by an existing account, in which
  case nothing will happen.

  You may want to use `get_or_create_account/1` instead.
  """
  @spec create_account(map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create_account(attrs) do
    attrs
    |> Account.changeset()
    |> repo().insert(
      on_conflict: :nothing,
      conflict_target: [:identifier]
    )
  end

  @doc """
  Gets or create an account with the given attributes.

  An account will be created unless an account already exists with the given identifier.

  If an account already exists with the identifier, it will be returned instead.
  """
  @spec get_or_create_account(map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_account(attrs) do
    case create_account(attrs) do
      {:ok, %{id: nil}} -> get_account_by_identifier(attrs.identifier)
      result -> result
    end
  end

  @doc """
  Gets an account by unique identifier.

  Returns `{:ok, account}` if an account exists for that identifier, otherwise `{:error, :not_found}`
  """
  @spec get_account_by_identifier(binary()) :: {:ok, Account.t()} | {:error, :not_found}
  def get_account_by_identifier(identifier) do
    case repo().get_by(Account, identifier: identifier) do
      nil -> {:error, :not_found}
      account -> {:ok, account}
    end
  end

  @doc """
  Gets a transaction by id.
  """
  @spec get_transaction(non_neg_integer()) :: {:ok, Transaction.t()} | {:error, :not_found}
  def get_transaction(id) do
    Transaction
    |> repo().get(id, preload: [entries: :account])
    |> case do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end

  @doc """
  Creates a transaction with the given attributes.
  """
  @spec create_transaction(map()) :: {:ok, Transaction.t()} | {:error, Ecto.Changeset.t()}
  def create_transaction(attrs) do
    attrs
    |> Transaction.changeset()
    |> repo().insert()
  end

  @doc """
  Deletes a transaction and all its entries.

  In theory, we should never delete a transaction, but in some cases it might be useful.

  We don't have the typycal accounting concept of "periods" and "closing",
  so we allow transactions to be deleted if needed.
  """
  def delete_transaction(%Transaction{} = transaction) do
    transaction = repo().preload(transaction, :entries)
    repo().delete(transaction)
  end

  @doc """
  Calculates the account balance for a given account or account id.

  First, all entries affecting that account are retrieved.
  Then, entries increase the account balance if the account's type matches the entry's type,
  or decrease the balance otherwise.

  For example, a debit entry will increase the balance of a debit account,
  but decrease it for credit accounts, and vice-versa.

  You may optionally provide an `Ecto.Query` to further filter
  the entries from which the account balance will be calculated.
  """
  @spec account_balance(Account.t() | binary() | non_neg_integer(), Ecto.Query.t() | module()) ::
          {:ok, Decimal.t()} | {:error, :not_found}
  def account_balance(account, entries_query \\ Entry)

  def account_balance(%Account{} = account, entries_query) do
    entries =
      entries_query
      |> where(account_id: ^account.id)
      |> repo().all()

    {:ok, calculate_balance(account, entries)}
  end

  def account_balance(account_ids, entries_query) when is_list(account_ids) do
    accounts =
      Account
      |> where([a], a.id in ^account_ids)
      |> repo().all()

    entries =
      entries_query
      |> where([e], e.account_id in ^account_ids)
      |> repo().all()

    balances =
      entries
      |> Enum.group_by(& &1.account_id)
      |> Enum.into(%{}, fn {account_id, entries} ->
        account = Enum.find(accounts, &(&1.id == account_id))
        {account_id, calculate_balance(account, entries)}
      end)

    {:ok, balances}
  end

  def account_balance(account_id, entries_query) do
    case repo().get(Account, account_id) do
      nil -> {:error, :not_found}
      account -> account_balance(account, entries_query)
    end
  end

  defp calculate_balance(%Account{} = account, entries) do
    entries
    |> Enum.map(&Entry.effective_amount(&1, account))
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end
end
