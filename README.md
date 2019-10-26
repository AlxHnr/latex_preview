**Deprecated!** Use [vimtex](https://github.com/lervag/vimtex) instead. It
can launch your PDF viewer and does asynchronous continuous compilation.
[Vimtex](https://github.com/lervag/vimtex) has superior error handling and
can handle documents which are split into multiple files.

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

## Frequently asked questions

### How is it different from [vim-latex-live-preview](https://github.com/xuhdev/vim-latex-live-preview)?

Years ago i was using Xuhdev's [vim-latex-live-preview](https://github.com/xuhdev/vim-latex-live-preview),
but was unhappy with lots of things. It wasn't possible to define custom
events that trigger a rebuild. Neither did it create a temporary directory
for all the output and clutter. The plugin had also other quirks and things
i disliked. So i wrote my own, which was superior back then. But nowadays?
I don't know. Development on [vim-latex-live-preview](https://github.com/xuhdev/vim-latex-live-preview)
seems to be active, so i can't tell whats better.

### Does it use Neovims/Vim-8's async features?

No. This plugin is much older than both of these. It implements its own
async spawning of commands. This has the disadvantage that the first build
is blocking. On non-blocking builds, error messages are silently ignored.
Use `LatexPreviewRebuild` to get the error message if something is messy.
