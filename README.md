# Tune

Tune is a Spotify browser and remote application with a focus on performance and integration with other services.

It's available at <https://tune.fullyforged.com>.

# Initial setup

First of all, we need working installations of Elixir and Erlang. The
recommended way to achieve this is via [asdf](https://asdf-vm.com/#/). Once
it's installed and working, you can run `asdf install` from the project root to
install the correct versions required by Ada (see the `.tool-versions` file for
details).

Next, make sure you setup the required environment variables as detailed in
`.env` by copying the file to `.env.local` and adjusting values as needed.

Please see the [Vapor
docs](https://hexdocs.pm/vapor/Vapor.Provider.Dotenv.html#content) for more
detail on the dotenv configuration provider.

To create secrets, (e.g. for `SECRET_KEY_BASE`), use `mix phx.gen.secret`.

Next you can install all dependencies with `mix setup`.

# Workflows

## Development

- Start the application with `mix phx.server`
- To start the application and an IEx console connected to it, use `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Tests, dialyzer and credo

You can run tests with `mix test`, dialyzer with `mix dialyzer` and Credo with `mix credo`.

## Deployment

The project is setup to deploy on Heroku, please make sure you:

- configure environment variables
- add the buildpacks detailed at <https://hexdocs.pm/phoenix/heroku.html>
