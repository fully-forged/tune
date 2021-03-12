import { lsMock } from "../test-helpers";
import VolumeSlider from "../VolumeSlider";

test("on change, it sends the set_volume event", () => {
  const slider = document.createElement("input");
  slider.type = "range";
  const ls = lsMock(slider, VolumeSlider);

  ls.mounted();
  slider.value = "50";
  ls.trigger("change");

  expect(ls.pushEvent).toHaveBeenCalledWith("set_volume", {
    volume_percent: 50,
  });
});
