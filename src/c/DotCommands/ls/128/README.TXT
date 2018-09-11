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

NOTES:

The output format is limited to -l for now and chosen to
fit in 32 columns.  The default is to list 8.3 filenames.

Try a variation like this one in 64 column mode:

.ls --gdf -AR --time-style=locale --lfn=on


aralbrec@z88dk.org
