export default {
  mounted() {
    this.el.addEventListener("click", (e) => {
      const positionMs = Math.floor(
        (e.target.max * e.offsetX) / e.target.offsetWidth
      );

      // Optimistic update
      this.el.value = positionMs;

      this.pushEvent("seek", { position_ms: positionMs });
    });
  },
};
