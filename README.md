# Tune

Tune is a Spotify browser and remote application with a focus on performance
and integration with other services.

You can see it in action at <https://tune.fullyforged.com>.

# Scope and features

In many ways Tune copies the official Spotify application: many views (e.g.
search or details for artists and albums) are tightly based on the equivalent
sections in the Spotify application. This is an intentional choice aimed at
reducing friction between applications.

Tune differs in these areas:

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

Tune can be used as a standalone player by selecting the appropriate option in
the device switch section in the mini player (note that it requires a Spotify
Premium subscription and [only some browsers are
supported](https://developer.spotify.com/documentation/web-playback-sdk/#supported-browsers)).

# Screenshots

## Album details

![Album details](https://raw.githubusercontent.com/fully-forged/tune/main/screenshots/album-details.jpg "Album details")

## Global Search

![Search](https://raw.githubusercontent.com/fully-forged/tune/main/screenshots/search.jpg "Search")

## Artist details

![Artist details](https://raw.githubusercontent.com/fully-forged/tune/main/screenshots/artist-details.jpg "Artist details")

## Top albums and recommendations

![Top albums and recommendations](https://raw.githubusercontent.com/fully-forged/tune/main/screenshots/top-albums-and-recommendations.jpg "Top albums and recommendations")

## Release radar

![Release radar](https://raw.githubusercontent.com/fully-forged/tune/main/screenshots/release-radar.jpg "Release radar")

# Initial setup

First of all, we need working installations of Elixir and Erlang. The
recommended way to achieve this is via [asdf](https://asdf-vm.com/#/). Once
it's installed and working, you can run `asdf install` from the project root to
install the correct versions required (see the `.tool-versions` file for
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
- to enable exception tracking via [Sentry](https://sentry.io), make sure you define a `SENTRY_DSN` environment variable

# Application structure

The `Tune` namespace defines the domain logic responsible to interact with the
Spotify API and maintain running sessions for each logged-in user.

The `TuneWeb` namespace defines authentication endpoints and the main
`LiveView` (`TuneWeb.ExplorerLive`) that powers the entire user interface.

Tune assumes multiple browser sessions for the same user, which is why it
defines a `Tune.Spotify.Session` behaviour with `Tune.Spotify.Session.Worker`
as its main runtime implementation.

Each worker is responsible to proxy interaction with the Spotify API, 
periodically poll for data changes, and broadcast corresponding events.

When a user opens a browser session, `TuneWeb.ExplorerLive` either starts or
simply reuses a worker named with the same session ID.

Each worker monitors its subscribers, so that it can shutdown when a user
closes their last browser window.

This architecture ensures that:

- The amount of automatic API calls against the Spotify API for a given user is
  constant and independent from the number of user sessions for the same user.
- Credential renewal happens in the background
- The explorer implementation remains entirely focused on UI interaction 

# Telemetry

The application exposes `TuneWeb.Telemetry` module with definitions for relevant metrics.

An instance of
[Phoenix.LiveDashboard](https://github.com/phoenixframework/phoenix_live_dashboard/)
is mounted at `/dashboard`. In production, the endpoint is protected by basic
auth (see `.env` for relevant environment variables).

# Limitations

- If you use Tune in combination with official Spotify clients, you will notice
  that if nothing is playing, after a while the miniplayer controls stop
  responding and you can't even play any song. This is due to a quirk in the
  Spotify devices API, which reports client devices as still connected.

  If you're running Tune on a platform where it can load the built-in audio
  player, you can just refresh the page for the player to reload, which has the
  side effect of "waking up" all other clients as well. At that point, you can
  select them from the device switcher and resume normal operation.

  If you're running Tune on a mobile device, your only option is to open the
  dormant client application, do a quick play/pause to wake it up and go back
  to Tune.

# Credits

- Mini player icons from [Bootstrap Icons](https://icons.getbootstrap.com/)
- Wikipedia icon made by [Freepik](https://www.flaticon.com/authors/freepik
  "Freepik") from [www.flaticon.com](https://www.flaticon.com/ "Flaticon")
- Last.fm icon made by [Pixel
  perfect](https://www.flaticon.com/authors/pixel-perfect "Pixel perfect") from
  [www.flaticon.com](https://www.flaticon.com/ "Flaticon")
- YouTube icon made by [Freepik](https://www.flaticon.com/authors/freepik
  "Freepik") from [www.flaticon.com](https://www.flaticon.com/ "Flaticon")
