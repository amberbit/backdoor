import {CodeJar} from 'codejar';
import {withLineNumbers} from 'codejar/linenumbers';
import hljs from 'highlight.js';
import 'highlight.js/styles/dracula.css';

export const EditorInput = {
  mounted() {
    this.editor = this.el;

    const jar = CodeJar(this.editor, withLineNumbers(hljs.highlightElement), {tab: '  ', preserveIdent: false});

    jar.onUpdate(code => {
      this.pushEvent("set_input_value", {command: {text: code}});
    });

    this.handleEvent("new_input_value", ({command: {text: code}}) => {
      if (jar.toString() !== code) {
        jar.updateCode(code);
      }
    })

    this.editor.addEventListener('keydown', e => {
      if (e.keyCode == 13 && (e.metaKey || e.ctrlKey)) {
        this.pushEvent("execute", {});
      }
    });
  },

  destroyed() {
    if (this.editor)
      this.editor.destroy();
  }
}

