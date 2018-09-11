This is a near complete implementation of unix "ls" that
is capable of sorting directories with thousands of entries.

TODO:

* Add different list styles
  Currently -l is always generated

* Change listing format depending on column width

* Add filename formatting with flag characters
  and filename colouring.

* Parse the LS_COLOR environment variable for
  colouring information.  Currently this environment
  variable and TIME_STYLE are both read but only
  TIME_STYLE is processed.

ISSUES:

DOS_CATALOG is repeatedly called to match filename
strings.  This slows the listing considerably; it is not
the sorting that slows things down.

This can be helped by using F_READDIR directly if the
match string does not contain wildcards and by retrieving
many more matches than one at a time from each DOS_CATALOG
call.

NOTES:

The output format is limited to -l and chosen to fit in
32 columns.  The default is to list 8.3 filenames.

Try a variation like this one in 64 column mode:

.ls --gdf -AR --time-style=locale --lfn=on

If a listing takes too long you can break and use the
fast (and more limited) 48k version .lsq, at least until
the speed issues have been sorted out.


aralbrec@z88dk.org
