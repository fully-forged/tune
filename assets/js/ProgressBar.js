export default {
  mounted() {
    this.el.addEventListener("click", (e) => {
      // The progress bar is measure in milliseconds,
      // with `min` set at 0 and `max` at the duration of the track.
      //
      // [--------------------------X-----------]
      // 0                          |       offsetWidth
      //                            |
      // [--------------------------] e.target.offsetX
      //
      // When the user clicks on the progress bar (represented by X), we get
      // the position of the click in pixels (e.target.offsetX).
      //
      // We know that we can express the relationship between pixels
      // and milliseconds as:
      //
      // e.target.offsetX : e.target.offsetWidth = X : max
      //
      // To find X, we do:
      const positionMs = Math.floor(
        (e.target.max * e.offsetX) / e.target.offsetWidth
      );

      // Optimistic update
      this.el.value = positionMs;

      this.pushEvent("seek", { position_ms: positionMs });
    });
  },
};
