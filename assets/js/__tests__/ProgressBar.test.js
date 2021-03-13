import { lsMock } from "../test-helpers";
import ProgressBar from "../ProgressBar";

test("for premium accounts, it sends the seek event on click", () => {
  document.body.innerHTML = `<progress max="300000">120000</progress>`;

  const progress = document.querySelector("progress");

  const ls = lsMock(progress, ProgressBar);

  ls.mounted();

  const evt = new MouseEvent("click", { offsetX: 10 });
  // Events defined in Jest Node's environment do not have all required
  // properties, so we hardcode the necessary offset
  evt.offsetX = 500;

  // The MouseEvent doesn't have all needed values set, so we need to
  // mock the getter used to return offsetWidth.
  jest.spyOn(progress, "offsetWidth", "get").mockReturnValue(1000);

  ls.trigger(evt);

  expect(ls.pushEvent).toHaveBeenCalledWith("seek", {
    position_ms: 150000,
  });
});
