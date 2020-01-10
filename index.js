import "./lib/codemirror.css";
import "./src/js/code-editor.js";
import "./style.css";
const { Elm } = require("./src/Main.elm");
const pagesInit = require("elm-pages");

const imageAssets = {};

pagesInit({
  mainElmModule: Elm.Main,
  imageAssets
});
