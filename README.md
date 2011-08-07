dash-r (-r) is a shim for allowing use of Mercurial-style local version numbers
in Git.  It is meant to complement
[Easy Git](http://people.gnome.org/~newren/eg/) in making Git easier to grok for
newbies (like myself).

Usage Examples: 

    -r  # prints git log w/ revision numbers
    git <command> `-r 3`  # operate on the fourth commit
    git diff `-r 1..-2`  # diff the second commit to HEAD^

(Assuming you installed the program as "-r")
