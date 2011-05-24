#!/usr/bin/env ruby

# -r -- git revisions numbers at last!
# Copyright 2011  James M. Jensen II <badocelot@badocelot.com>
# License: GNU General Public License, Version 2 or later

def parse_revision rev
	if rev == "0"
		0
	elsif rev.to_i != 0 and rev !~ /[\._]/ then
		rev.to_i
	else
		rev
	end
end

if __FILE__ == $0
	# get the checksums
	revs = `git log --pretty=oneline`.split("\n").map{|commit| commit.split[0]}

	if (ARGV.length == 0) then
		# print the log, w/ rev #'s
		log = `git log`
		revs.length.times do |count|
			log.gsub!(/^(commit) (#{revs[count]})$/,
			          "\\1 #{revs.length - (count + 1)}  id: \\2")
		end
		puts log
	else
		revs.reverse!
		revno = ARGV.shift

		# check for ranges
		if revno =~ /\.\.\./ then
			first, last = revno.split('...').map {|rev| parse_revision rev}
			puts "%s..%s" % [(first.is_a? Fixnum) ? revs[first] : first,
				             (last != nil) ? ((last.is_a? Fixnum) ? revs[last] \
				                                                  : last) \
				                           : ""]
		elsif revno =~ /\.\./ then
			first, last = revno.split('..').map {|rev| parse_revision rev}
			puts "%s..%s" % [(first.is_a? Fixnum) ? revs[first] : first,
				             (last != nil) ? ((last.is_a? Fixnum) ? revs[last] \
				                                                  : last) \
				                           : ""]
		else
			# but if there's only one...
			revno = parse_revision revno
			if revno.is_a? Fixnum then
				puts revs[revno]
			else
				puts revno
			end
		end
	end
end
