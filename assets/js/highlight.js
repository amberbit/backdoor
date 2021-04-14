import hljs from "highlight.js";
import "highlight.js/styles/dracula.css";

export const Highlight = {
  mounted() {
    hljs.highlightElement(this.el);
  },
};
