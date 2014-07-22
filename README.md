# LaTeX Preview

A simple plugin, that automatically (re)builds your LaTeX files, launches
your document viewer and manages all the process tracking and cleanup
stuff for you.

![preview.gif](https://raw.github.com/AlxHnr/latex_preview/master/preview.gif)

Here latex_preview is configured to rebuild your file each time it changes.
By default it only rebuilds your file when you save it, but you can easily
define custom autocmds that will trigger a rebuild.

## Requirements and installation

For installation refer to the manual of your plugin manager.

This plugin was only testet on Linux and operates by spawning shell
commands in the background. But it should work on all platforms that
support this. It also depends on Vim's mkdir function. This plugin assumes
that the document viewer auto-refreshes the document on modifications.

By default it takes the first document viewer from the following list that
it finds:

	* evince
	* okular
	* zathura
	* qpdfview

To use your own document viewer, please refer to the documentation of
latex_preview.

It also searches for 'pdflatex' by default. Of course you can use any other
program to build your files, but this is covered by the documentation.

## Commands

These are only brief explanations of some commands. For more detailed
informations, see `:help latex_preview`.

### `:LatexPreview`

Builds the current buffer and previews the result. It will update the
result each time you save your file. (Unless you have reconfigured this).
If you exit Vim, latex_preview will clean up for you and will shut down all
processes, like the document viewer, properly.

### `:LatexPreviewStop`

Stops previewing your file, shuts down everything properly and cleans up.
latex_preview will also clean up if you exit Vim, so you don't need to call
this explicitly.

### `:LatexPreviewRebuild`

Rebuilds the current file and shows you the errors on failure.

### `:LatexPreviewExport`

Builds your file and exports the resulting document. It takes the path to
the output file as argument. This command doesn't require latex_preview to
be running.

Example:

	:LatexPreviewExport ~/Documents/my_document.pdf

## License

Released under the zlib license.
