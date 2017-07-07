A simple plugin, which automatically (re)builds your LaTeX files, launches
your document viewer and manages all the process tracking and cleanup
stuff.

![preview.gif](https://raw.github.com/AlxHnr/latex_preview/master/preview.gif)

By default this plugin updates your preview only when you save your
document. To update your preview in realtime, like in the demo above, just
add the following line to your vimrc. But beware of the high CPU usage.

```vim
let g:latex_preview#rebuild_events = 'TextChanged,TextChangedI'
```

This plugin was only tested on Linux, but it should work on all platforms
which support spawning shell commands in the background. By default it will
search for one of the following document viewers.

* [Evince](https://wiki.gnome.org/Apps/Evince)
* [Okular](https://okular.kde.org/)
* [zathura](http://pwmt.org/projects/zathura/)
* [qpdfview](https://launchpad.net/qpdfview)

To use your own document viewer refer to the documentation of
latex\_preview.

### Notes on packages like [minted](https://github.com/gpoore/minted)

Latex\_preview manages its own temporary build directory. This causes build
failure with some packages. Thus it is necessary to pass the build path to
the package. Example for minted:

```latex
\usepackage[outputdir=.latex_preview_build_dir]{minted}
```

Minted calls external programs during build. Most LaTeX distributions
disable this for security reasons. To enable it again, add this to your
.vimrc or init.vim:

```vim
let g:latex_preview#compiler_args = '-shell-escape'
```

## Commands

These are only brief explanations of some commands. For more detailed
informations, see `:help latex_preview`.

### LatexPreview

Builds the document in the current buffer and launches the preview session.
If you exit Vim, latex\_preview will clean up for you and terminate all
processes properly.

### LatexPreviewStop

Stops the preview session and cleans up internal temporary stuff. You don't
need to call this explicitly, since latex\_preview will do this for you
when you exit Vim.

### LatexPreviewRebuild

Rebuilds the current document and shows errors on failure.

### LatexPreviewExport

Build and export the current document to a given path or filename. This
command doesn't require a running preview session.

Example:

```vim
:LatexPreviewExport ~/Documents/my_document.pdf
```
