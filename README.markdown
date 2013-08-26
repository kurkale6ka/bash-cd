cd with weighted marks
======================

This is a wrapper script for the **Bash** builtin `cd` command.
Every time you change directory it updates a bookmarks file either by adding a
new entry or by increasing the weight of an existing one.

The format is: _weight directory (optional bookmark)_  
Example: `3 /usr/src/linux`

Once you've been to the above location you can return by simply typing:

`cd li` (or any string part of the directory)

As an additional bonus you could have a named bookmark for that location by
typing `cdb bookmark` while in the right location

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
