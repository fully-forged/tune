export default {
  mounted() {
    const logo = document.querySelector("#logo a");
    const modal = document.querySelector("#help");
    const modalOverlay = document.querySelector("#modal-overlay");
    const closeButton = document.querySelector("#close-button");
    const openButton = document.querySelector("#open-button");
    const searchInput = document.getElementById("q");
    const navBar = document.getElementById("navbar");
    const deviceSelector = document.getElementById("device");

    closeButton.addEventListener("click", function () {
      modal.classList.toggle("closed");
      modalOverlay.classList.toggle("closed");
    });

    openButton.addEventListener("click", function () {
      modal.classList.toggle("closed");
      modalOverlay.classList.toggle("closed");
    });

    document.addEventListener("keydown", (event) => {
      switch (event.key) {
        case " ":
          event.preventDefault();
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
        case "h":
          logo.click();
          break;
        case "?":
          modal.classList.toggle("closed");
          modalOverlay.classList.toggle("closed");
          break;
        case "Escape":
          modal.classList.add("closed");
          modalOverlay.classList.add("closed");
          break;
        case "/":
          event.preventDefault();
          navBar.scrollIntoView();
          searchInput.focus();
          break;
        case "q":
          deviceSelector.focus();
          break;
        case "n":
          // We delay resolving this element as it gets added
          // and removed as needed
          const nextPageLink = document.querySelector("#next-page");
          if (nextPageLink) {
            nextPageLink.click();
          }
          break;
        case "p":
          // We delay resolving this element as it gets added
          // and removed as needed
          const previousPageLink = document.querySelector("#previous-page");
          if (previousPageLink) {
            previousPageLink.click();
          }
          break;
        default:
          break;
      }
    });
  },
};
