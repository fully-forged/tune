export default {
  mounted() {
    this.el.addEventListener("change", (e) => {
      this.pushEvent("set_volume", { volume_percent: e.target.valueAsNumber });
    });
  },
};
