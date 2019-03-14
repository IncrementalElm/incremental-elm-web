customElements.define(
  "code-editor",
  class extends HTMLElement {
    constructor() {
      super();
      this._editorValue =
        "-- If you see this, the Elm code didn't set the value.";
    }

    get editorValue() {
      return this._editorValue;
    }

    set editorValue(value) {
      if (this._editorValue === value) return;
      this._editorValue = value;
      if (!this._editor) return;
      this._editor.setValue(value);
    }

    connectedCallback() {
      this._editor = CodeMirror(this, {
        identUnit: 4,
        mode: "elm",
        lineNumbers: true,
        value: this._editorValue
      });
    }
  }
);
