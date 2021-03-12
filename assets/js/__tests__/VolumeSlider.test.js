import VolumeSlider from "../VolumeSlider";

test("on change, it sends the set_volume event", () => {
  const slider = document.createElement("input");
  slider.type = "range";
  const ls = {
    el: slider,
    pushEvent: jest.fn(),
    mounted: VolumeSlider.mounted,
  };

  ls.mounted();
  slider.value = "50";
  const evt = new Event("change");
  ls.el.dispatchEvent(evt);
  expect(ls.pushEvent).toHaveBeenCalledWith("set_volume", {
    volume_percent: 50,
  });
});
