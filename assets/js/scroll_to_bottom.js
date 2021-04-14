export const ScrollToBottom = {
  mounted() {
    this.handleEvent("scroll_to_bottom", () => {
      this.el.scrollTop = this.el.scrollHeight;
    });
  },
};
