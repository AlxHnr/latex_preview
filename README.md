# LaTeX Preview

A simple plugin, which automatically (re)builds your LaTeX files, launches
your document viewer and manages all the process tracking and cleanup
stuff.

![preview.gif](https://raw.github.com/AlxHnr/latex_preview/master/preview.gif)

By default this plugin updates your preview only when you save your
document. To update your preview in realtime, like in the demo above, just
add the following line to your vimrc. But beware of the higher resource
usage this option may cause.

```vim
let g:latex_preview#rebuild_events = 'TextChanged,TextChangedI'
```

## Requirements and installation

For installation refer to the manual of your plugin manager.

This plugin was only tested on Linux, but it should work on all platforms
which support spawning shell commands in the background. This plugin relies
on the assumption, that the document viewer automatically reloads the
document on modifications.

By default it takes the first document viewer from the following list that
it finds:

* [Evince](https://wiki.gnome.org/Apps/Evince)
* [Okular](https://okular.kde.org/)
* [zathura](http://pwmt.org/projects/zathura/)
* [qpdfview](https://launchpad.net/qpdfview)

To use your own document viewer, please refer to the documentation of
latex\_preview.

This plugin uses the program 'pdflatex' to build documents. Of course any
other build program can be used, but this is covered by the documentation.

## Commands

These are only brief explanations of some commands. For more detailed
informations, see `:help latex_preview`.

### :LatexPreview

Builds the document in the current buffer and launches the preview session.
If you exit Vim, latex\_preview will clean up for you and terminate all
processes properly.

### :LatexPreviewStop

Stops the preview session and cleans up internal temporary stuff. You don't
need to call this explicitly, since latex\_preview will do this for you
when you exit Vim.

### :LatexPreviewRebuild

Rebuilds the current document and shows errors on failure.

### :LatexPreviewExport

Build and export the current document to a given path or filename. This
command doesn't require a running preview session.

Example:

```vim
:LatexPreviewExport ~/Documents/my_document.pdf
```

## License

Released under the zlib license.
