export default {
  mounted() {
    this.el.addEventListener("click", (e) => {
      let textToCopy = this.el.dataset.copyText;
      navigator.clipboard.writeText(textToCopy);
    });
  },
};
