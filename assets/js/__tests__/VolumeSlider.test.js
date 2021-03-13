import { lsMock } from "../test-helpers";
import VolumeSlider from "../VolumeSlider";

test("on change, it sends the set_volume event", () => {
  document.body.innerHTML = `<input type="range">`;
  const slider = document.querySelector("input");

  const ls = lsMock(slider, VolumeSlider);

  ls.mounted();
  slider.value = "50";
  const evt = new Event("change");
  ls.trigger(evt);

  expect(ls.pushEvent).toHaveBeenCalledWith("set_volume", {
    volume_percent: 50,
  });
});
