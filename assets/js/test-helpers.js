const lsMock = (el, hook) => ({
  el,
  pushEvent: jest.fn(),
  mounted: hook.mounted,
  trigger: (evtName) => {
    const evt = new Event(evtName);
    return el.dispatchEvent(evt);
  },
});
export { lsMock };
