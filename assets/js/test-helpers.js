const lsMock = (el, hook) => ({
  el,
  pushEvent: jest.fn(),
  mounted: hook.mounted,
  trigger: (evt) => {
    return el.dispatchEvent(evt);
  },
});
export { lsMock };
