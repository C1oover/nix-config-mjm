import * as Popper from "@popperjs/core";

export const dropdownStore = {
  current: null,

  toggle(id) {
    if (this.current === id) {
      this.current = null;
    } else {
      this.current = id;
    }
  },

  hide() {
    this.current = null;
  },
};

export const dropdownData = (dropdownId, popperOpts) => ({
  dropdownId,
  popper: null,

  init() {
    let dropdown = document.getElementById(this.dropdownId);
    this.popper = Popper.createPopper(this.$el, dropdown, popperOpts);
  },

  isExpanded() {
    this.$store.dropdown.current === this.dropdownId;
  },

  toggle() {
    this.$store.dropdown.toggle(this.dropdownId);
    this.$nextTick(() => {
      this.popper.update();
    });
  },
});
