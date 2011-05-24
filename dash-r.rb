#!/usr/bin/env ruby

# -r -- git revisions numbers at last!
# Copyright 2011  James M. Jensen II <badocelot@badocelot.com>
# License: GNU General Public License, Version 2 or later

revs = `git log --pretty=oneline`.split("\n").map { |commit| commit.split[0] }

if (ARGV.length == 0) then
	revs.length.times do |count|
		puts "%d: %s" % [revs.length - (count + 1), revs[count]]
	end
else
	revs.reverse!
	revno = ARGV.shift

	# if there's only one...
	if revno !~ /\.\./ and revno !~ /:/ then
		revno = revno.to_i
		puts revs[revno]
	end
end

