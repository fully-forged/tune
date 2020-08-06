// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";
import { Socket } from "phoenix";
import NProgress from "nprogress";
import { LiveSocket } from "phoenix_live_view";

let Hooks = {};
let spotifySDKReady = false;

Hooks.ProgressBar = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      const positionMs = Math.floor(
        (e.target.max * e.offsetX) / e.target.offsetWidth
      );

      this.pushEvent("seek", { position_ms: positionMs });
    });
  },
};

Hooks.AudioPlayer = {
  player: null,
  initPlayer() {
    this.player = new Spotify.Player({
      name: "Tune Player",
      getOAuthToken: (cb) => {
        cb(this.token());
      },
    });

    this.player.addListener("ready", () => {
      this.pushEvent("refresh_devices", {});
    });
  },
  token() {
    return this.el.dataset.token;
  },
  mounted() {
    if (spotifySDKReady) {
      this.initPlayer();
      this.player.connect();
    } else {
      window.addEventListener("spotify.ready", () => {
        this.initPlayer();
        this.player.connect();
      });
    }
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", () => NProgress.start());
window.addEventListener("phx:page-loading-stop", () => NProgress.done());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;

window.onSpotifyWebPlaybackSDKReady = () => {
  const event = new Event("spotify.ready");
  window.dispatchEvent(event);
  spotifySDKReady = true;
};
