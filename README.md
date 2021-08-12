# Tune

![CI Status](https://github.com/fully-forged/tune/workflows/Tune%20CI/badge.svg)

## About

Tune is a Spotify browser and remote application with a focus on performance
and integration with other services.

You can see it in action at <https://tune.fullyforged.com>.

### Album details

![Album details](https://raw.githubusercontent.com/fully-forged/tune/main/screenshots/album-details.jpg "Album details")

### Global Search

![Search](https://raw.githubusercontent.com/fully-forged/tune/main/screenshots/search.jpg "Search")

### Artist details

![Artist details](https://raw.githubusercontent.com/fully-forged/tune/main/screenshots/artist-details.jpg "Artist details")

### Top albums and recommendations

![Top albums and recommendations](https://raw.githubusercontent.com/fully-forged/tune/main/screenshots/top-albums-and-recommendations.jpg "Top albums and recommendations")

### Release radar

![Release radar](https://raw.githubusercontent.com/fully-forged/tune/main/screenshots/release-radar.jpg "Release radar")

## Usage

### Scope and features

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

### Keyboard shortcuts

- <kbd>Space</kbd>: Play/Pause
- <kbd>h</kbd>: Home
- <kbd>a</kbd>: Prev
- <kbd>d</kbd>: Next
- <kbd>w</kbd>: Volume up
- <kbd>s</kbd>: Volume down
- <kbd>/</kbd>: Focus search input
- <kbd>q</kbd>: Focus device selector
- <kbd>n</kbd>: When available, go to the next page
- <kbd>p</kbd>: When available, go to the previous page
- <kbd>?</kbd>: Display a modal dialog with available shortcuts
  
### Free vs. Premium Subscriptions

| Feature                   | Free subscription | Premium Subscription |
|---------------------------|:-----------------:|:--------------------:|
| Search                    |         ✅         |           ✅          |
| Artist/Album/etc. details |         ✅         |           ✅          |
| Suggestions               |         ✅         |           ✅          |
| Release radar             |         ✅         |           ✅          |
| Miniplayer controls       |         ❌         |           ✅          |
| Device chooser            |         ❌         |           ✅          |
| Embedded audio player     |         ❌         | ✅ (on some browsers) |

Due to limitations imposed by Spotify, users with free subscriptions cannot use the embedded
audio player, nor they can control other devices via Tune's UI. If you have a
free subscription, those UI elements are not visible as they're ineffective.

For users with Premium subscriptions, Tune can be used as a standalone player by selecting the
appropriate option in the device switch section in the mini player (note that [only some browsers are
supported](https://developer.spotify.com/documentation/web-playback-sdk/#supported-browsers)).

### Data retention and privacy

Tune doesn't have any persistent storage: upon successful authentication,
credentials are only stored in your browser's cookies and kept in memory in the application.

Credentials are cleared at most 30 seconds after you close the last browser
session, even if you don't explicitly logout.

At this point in time, credentials may be printed in logs and/or crash reports.

### Duplicated content

In some cases, search results or specific listings will display duplicated
content (e.g. the exact same album twice). This is due to the Spotify API
returning duplicated results which only differ in the ID.

It's not clear why this happens: it could be that the artist uploaded the same
album multiple times, it could be that different editions are available in
specific territories.

### Issues with devices and playback

If you use Tune in combination with official Spotify clients, you will notice
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

More information on the related [Spotify documentation
page](https://developer.spotify.com/documentation/web-api/guides/using-connect-web-api/#devices-not-appearing-on-device-list).

## Development

### Setup

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

### Running the application

- Start the application with `mix phx.server`
- To start the application and an IEx console connected to it, use `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Tests, dialyzer and Credo

You can run tests with `mix test`, dialyzer with `mix dialyzer` and Credo with `mix credo`.

The application also includes a minimal JS test suite (currently used as a
playground to understand how to effectively test Phoenix LiveView hooks). You
can run it with `cd assets` and then `npm test`.

### Application structure

The `Tune` namespace defines the domain logic responsible to interact with the
Spotify API and maintain running sessions for each logged-in user.

The `TuneWeb` namespace defines authentication endpoints and the main
`LiveView` (`TuneWeb.ExplorerLive`) that powers the entire user interface.

Tune assumes multiple browser sessions for the same user, which is why it
defines a `Tune.Spotify.Session` behaviour with `Tune.Spotify.Session.HTTP`
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

### Telemetry

The application exposes `TuneWeb.Telemetry` module with definitions for relevant metrics.

An instance of
[Phoenix.LiveDashboard](https://github.com/phoenixframework/phoenix_live_dashboard/)
is mounted at `/dashboard`. In production, the endpoint is protected by basic
auth (see `.env` for relevant environment variables).

## Deployment

The project is setup to deploy on Heroku, please make sure you:

- configure environment variables
- add the buildpacks detailed at <https://hexdocs.pm/phoenix/heroku.html>
- to enable exception tracking via [Sentry](https://sentry.io), make sure you define a `SENTRY_DSN` environment variable
- to enable metrics tracking via [AppSignal](https://appsignal.com), make sure you defined the environment variables listed at <https://docs.appsignal.com/elixir/configuration/#minimal-required-configuration>

## Credits

All content and metadata is provided by Spotify unless explicitly stated.
Content is owned by many different right holders.

Icons:

- Spotify icon by
  [Spotify](https://developer.spotify.com/documentation/general/design-and-branding/#using-our-logo
  "Spotify Logo")
- Wikipedia icon by [Freepik](https://www.flaticon.com/authors/freepik
  "Freepik") from [www.flaticon.com](https://www.flaticon.com/ "Flaticon")
- Last.fm icon by [Pixel
  perfect](https://www.flaticon.com/authors/pixel-perfect "Pixel perfect") from
  [www.flaticon.com](https://www.flaticon.com/ "Flaticon")
- YouTube icon by [Freepik](https://www.flaticon.com/authors/freepik
  "Freepik") from [www.flaticon.com](https://www.flaticon.com/ "Flaticon")
- All remaining icons from [Remix Icon](https://remixicon.com/)

## Code of Conduct

Available at <https://github.com/fully-forged/tune/blob/main/CODE_OF_CONDUCT.md>.

## License

Available at <https://github.com/fully-forged/tune/blob/main/LICENSE>.
