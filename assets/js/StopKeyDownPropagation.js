export default {
  mounted() {
    this.el.addEventListener("keydown", (event) => {
      if (event.key == "Escape") {
        this.el.blur();
      } else {
        event.stopPropagation();
      }
    });
  },
};
