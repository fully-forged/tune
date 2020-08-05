# Tune

Tune is a Spotify browser and remote application with a focus on performance and integration with other services.

It's available at <https://tune.fullyforged.com>.

# Scope and features

In many ways Tune copies the official Spotify application: search, detail views
for albums, artists, etc. are tightly based on the equivalent sections in the
Spotify application. This is an intentional choice aimed at reducing friction
between applications.

The key differences between the two applications are:

- Tune does not (for the time being) include an audio player: it acts as a
  remote for one or more other players.
- Performance: Tune is extremely light, as for the most part is a
  server-rendered application, which makes it suitable to use on a wide range
  of devices and operating systems (think Linux on a Raspberry PI). Most of its
  functionality works without JavaScript and is exposed via a proper URL.
- Integration: Tune tries to connect items like artists, albums or songs to
  other sources of information, so that for example you can use convenient
  links to read the history of a band on Wikipedia.
- Recommendations: Tune offers suggestions based on a combination of what's
  provided by Spotify and some custom logic (loosely based on what you've been
  listening in a specific time period). The logic is an almost direct porting of
  how I search for new music, so it might not work for you.

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
