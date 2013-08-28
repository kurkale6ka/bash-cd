cd with weighted marks
======================

This is a wrapper script for the **Bash** builtin `cd` command.
Every time you change directory it updates a bookmarks file either by adding a
new entry or by increasing the weight of an existing one.

The format is: _weight directory (optional bookmark)_  
Example: `3 /usr/src/linux`

Once you've been to the above location you can return by simply typing:

`cd li` (or any string part of the directory)

Filtering further is also possible:

`cd sr li` will ensure you don't end up in `/usr/share/lib` if it has a higher score!

As an additional bonus you have the possibility to create a named bookmark by
typing `cdb bookmark` while in the desired location

Example:
```
cd /usr/src/linux
cdb kernel
```

Now the entry is: `4 /usr/src/linux kernel`, thus you could come back with
`cd ker` or `cd rne` or ...

Setup
-----

* `$ touch ~/.cdmarks`
* `source` the script in your `~/.bashrc`
* `$ exec bash`

You are ready!

_Note 1_: `cds filter ...` will list your bookmarks and `cdc` can help you with
migrating a personal `~/.cdmarks.skel` file

_Note 2_: Never use ~ in `~/.cdmarks.skel` or if manually entering bookmarks in
`~/.cdmarks` (use the value of **HOME** instead). Don't terminate paths with a `/`.

_Note 3_: Get help with `cdh`
