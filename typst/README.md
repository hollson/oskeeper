# Usage

Use VSCodium and install a plugin called [TinyMist](https://github.com/Myriad-Dreamin/tinymist).

Then open the `*.typ` and use it to preview or generate into PDF.

Refer to the `sample.typ` for the examples.

## Installation

If you have installed the tinymist plugin above, you don't need to install typst again as it comes bundled with it. If you wish to compile manually then you need to install the following.

Install the fonts from `fonts/` dir

```bash
brew install typst
```


## Compilation

You can compile the `.typ` files using the plugin, you should see a `Export PDF` that you can use to export.

Compile pdf
```bash
typst compile --font-path fonts/ sample.typ sample.pdf
```
