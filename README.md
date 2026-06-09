# GuitarVault

A personal instrument collection manager built with Phoenix LiveView. Track your guitars and basses, organize them into vaults, log events (purchases, sales, repairs), and attach photos — all behind a secure user account.

## Features

- **Instrument vault** — Add guitars and basses with details like brand, model, year, and color
- **Event log** — Record purchases, sales, and other events per instrument
- **Image gallery** — Upload and caption photos for each instrument
- **Sold gear toggle** — Hide or show sold instruments
- **Search** — Filter your vault by name in real time
- **Authentication** — Email/password accounts with confirmation and session management

## Tech stack

- [Elixir](https://elixir-lang.org/) + [Phoenix 1.8](https://www.phoenixframework.org/) with LiveView
- SQLite via `ecto_sqlite3`
- Tailwind CSS v4
- File uploads stored under `priv/uploads/`

## Getting started

```bash
mix setup          # install deps, create & migrate the database
mix phx.server     # start the dev server at http://localhost:4000
```

Or run inside IEx for an interactive shell:

```bash
iex -S mix phx.server
```

## Development

```bash
mix test           # run the test suite
mix precommit      # format, credo, and test (run before committing)
```
