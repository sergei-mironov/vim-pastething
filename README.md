<!--
vim: spell
-->

Pastething
==========

This repository contains a VIM paste pre-processing plugin suitable for editing text markup like
Markdown or LaTeX.

Features
--------

The plugin provides `p` and `P` handlers for normal, insert and visual editing modes. Their
invocation triggers the following workflow:

1. Plugin collects information about the paste action:
   * Type of the current file
   * Type of the content to be pasted. Currently the plugin distinguishes:
     + HTTP(s) URLs.
     + Image blobs (either `xclip` or `wl-paste` is required for this).
   * Possible text for annotations (e.g. gets the active visual selection)
2. Substitution pattern is requested from the pre-configured dictionary. Example of the markdown
   pattern for images: `![%T%C](%U)` where `%T` stands for title, `%U` - for the URL and `%C` marks
   the cursor position after the paste is complete.
3. Finally, the plugin substitutes the information into the pattern and actually pastes
   the result into the buffer. For images the plugin saves blobs into a pre-configured
   directory and puts the path to the new file into the pattern.

Installation
------------

Put the repository into the Vim runtime search path by using your favorite plugin manager.

Configuration
-------------

1. Overwrite [global options](./vim/plugin/pastething.vim):
   ``` vim
   let g:pastething_insert_eol = 1
   let g:pastething_image_enabled = 1
   let g:pastething_xclip_path = '/path/to/xclip' " `xclip` to extract images from clipboard
   let g:pastething_image_dir = 'img' " Save extracted images into the `./img` directory
   ```

2. Setup the substitution patterns for the file types of interest.
   Example:
   * `./vim/ftplugin/markdown.vim`:
     ``` vim
     call g:pastething#pattern_set('markdown', g:pastething_type_url, "[%T%C](%U)")
     call g:pastething#pattern_set('markdown', g:pastething_type_img, "![%T%C](%U)")
     ```
   * `./vim/ftplugin/tex.vim`:
     ``` vim
     call g:pastething#pattern_set('tex', g:pastething_type_url, "\\href{%U}{%T%C}")
     ```

3. Setup the paste command mappings:
   ``` vim
   nnoremap p :call pastething#paste_normal("p")<CR>
   nnoremap P :call pastething#paste_normal("P")<CR>
   vnoremap p :call pastething#paste_visual("p")<CR>
   inoremap <Esc>p <C-o>:call pastething#paste_insert("P")<CR>
   ```


References
----------

* This plugin is inspired by [img-paste](https://github.com/img-paste-devs/img-paste.vim)
* [clipboard-image.nvim](https://github.com/ekickx/clipboard-image.nvim)
