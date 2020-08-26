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
    if (this.el.dataset.premium === "true") {
      this.el.addEventListener("click", (e) => {
        const positionMs = Math.floor(
          (e.target.max * e.offsetX) / e.target.offsetWidth
        );

        // Optimistic update
        this.el.value = positionMs;

        this.pushEvent("seek", { position_ms: positionMs });
      });
    }
  },
};

Hooks.VolumeSlider = {
  mounted() {
    this.el.addEventListener("change", (e) => {
      this.pushEvent("set_volume", { volume_percent: e.target.valueAsNumber });
    });
  },
};

Hooks.AudioPlayer = {
  player: null,
  initPlayer() {
    this.player = new Spotify.Player({
      name: this.playerName(),
      getOAuthToken: (cb) => {
        cb(this.token());
      },
    });

    this.player.addListener("ready", () => {
      this.pushEvent("refresh_devices", {});
      console.log("Device is ready");
    });

    this.player.addListener("initialization_error", console.error);
    this.player.addListener("authentication_error", console.error);
    this.player.addListener("account_error", console.error);
    this.player.addListener("playback_error", console.error);

    this.player.addListener("not_ready", ({ device_id }) => {
      console.warn("Device ID has gone offline", device_id);
    });
  },
  token() {
    return this.el.dataset.token;
  },
  playerName() {
    return this.el.dataset.playerId;
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

Hooks.GlobalShortcuts = {
  mounted() {
    document.addEventListener("keydown", (event) => {
      event.preventDefault();
      switch (event.key) {
        case " ":
          this.pushEvent("toggle_play_pause", {});
          break;
        case "a":
          this.pushEvent("prev", {});
          break;
        case "d":
          this.pushEvent("next", {});
          break;
        case "w":
          this.pushEvent("inc_volume", {});
          break;
        case "s":
          this.pushEvent("dec_volume", {});
          break;
        default:
          break;
      }
    });
  },
};

Hooks.StopKeyDownPropagation = {
  mounted() {
    this.el.addEventListener("keydown", (event) => event.stopPropagation());
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
