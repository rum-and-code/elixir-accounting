defmodule AccountingTest do
  use ExUnit.Case
  doctest Accounting

  test "greets the world" do
    assert Accounting.hello() == :world
  end
end
