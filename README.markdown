cd with weighted marks
======================

This is a script similar in functionality to **Bash**'s `pushd` and `popd`
builtin commands. Every time you change directory it updates a bookmarks file
either by adding a new entry or by increasing the weight of an existing one. The
marks with highest scores are at the top of the file so they get matched first.

The format is: _weight directory (optional bookmark)_
Example: `3 /usr/src/linux`

Once you've been to the above location you can return by simply typing:

`c li` (or any string part of the directory)

**_Note_**: You could also `<tab>` complete your filter in order to list all
possible locations; `c li<tab>` will generate a list of bookmarked and default
directories merged together. Use `cx li<tab>` if you want a bookmarked list only.

Filtering further is also possible:

`c sr li` will ensure you don't end up in `/usr/share/lib` if it has a higher score!

As an additional bonus you have the possibility to create a named bookmark (_no
spaces allowed_) by typing `cb bookmark` while in the desired location

Example:
```
c /usr/src/linux
cb kernel
```

Now the entry is: `4 /usr/src/linux kernel`, thus you could come back with
`c ker` or `c rne` or ...

Setup
-----

* `$ touch ~/.cdmarks`
* `source` the script in your `~/.bashrc`
* `$ exec bash`

You are ready!

**_Note 1_**: `cs filter ...` will list your bookmarks (similar to `<tab>`
completion) and `ci` can help you with migrating a personal `~/.cdmarks.skel` file

**_Note 2_**: Never use ~ in `~/.cdmarks.skel` or if manually entering bookmarks in
`~/.cdmarks` (use the value of `HOME` instead). Don't terminate paths with a `/`

**_Note 3_**: If you want to use a different name than `c`, put `alias
new_name=cd_bookmarks` after the `source` statement

**_Note 4_**: Get help with `ch`
