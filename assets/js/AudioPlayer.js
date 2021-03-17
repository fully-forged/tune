export default {
  player: null,
  initPlayer() {
    this.player = new Spotify.Player({
      name: this.deviceName(),
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
  deviceName() {
    return this.el.dataset.deviceName;
  },
  mounted() {
    if (window.spotifySDKReady) {
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
