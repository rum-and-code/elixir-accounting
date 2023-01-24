# Elixir Accounting

🚧 ALPHA STATUS - use at your own risk 🚧 

This library is the basis of a double-entry accounting system.

Whenever you need to track money movements in a project, this library will help you build a system that makes sense from an accounting perspective.

In order to understand what's going on in this library,
it is highly recommended that you go through a series of articles called
[Accounting for Developers](https://www.moderntreasury.com/journal/accounting-for-developers-part-i).

The `Accounting` module has some documentation that goes into more details.

## Installation

This library is not published as a Hex package.
To include it in your project, add the dependency to the `deps` function 
of your `mix.exs` file, pointing to this repository like so: 

```elixir
def deps do
  [
    {:accounting, github: "rum-and-code/elixir-accounting"},
  ]
end
```

This library has no branches or tags at the moment, but when it does, you will be able to pin your project to a specific version.

## Migrations

This library defines some Ecto models that will live in your database, however it will not run migrations for you.
To run this project's migrations, you need to generate a migration in your project:

```bash
mix ecto.gen.migration ElixirAccountingV1
```

And in that file, call the `Accounting.Migrations.V1.change/0` function:

```elixir
defmodule YourApp.Repo.Migrations.ElixirAccountingV1 do
  use Ecto.Migration

  def change do
    Accounting.Migrations.V1.change()
  end
end
```

When you then run `mix ecto.migrate`, you will see some `accounting_*` tables be created.

Note that you will have to do that for each and every migration that this project exposes (only 1 at the moment).

## Usage

TODO: document usage when it has been implemented in another project
