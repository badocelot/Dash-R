#!/usr/bin/env ruby

# Dash-R -- git revisions numbers at last!
# Copyright 2011  James M. Jensen II <badocelot@badocelot.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Format: [major, minor, bugfix, status]
DASH_R_VERSION = [0,9,0,'']

def parse_revision rev
	if rev == "0"
		0
	elsif rev.to_i != 0 and rev !~ /[\._]/ then
		rev.to_i
	else
		rev
	end
end

def commit_count
	`git log --pretty=format:'' | wc -l`.to_i + 1
end

if __FILE__ == $0 then
	if (ARGV.length == 0) then
		# Print the log, w/ rev numbers
		
		# Grab the normal log from git
		log = `git log`
		
		# Escape existing %'s
		log.gsub!('%','%%')
		
		# Replace the "commit <hash>" lines with something more useful...
		log.gsub!(/^(commit) ([0-9a-fA-F]{40})$/,
		          "\\1 %d  id: \\2")
		
		# Print the new log, with commit numbers, counting from zero
		#
		# Commit lines should now appear like:
		#
		#   commit 0  id: c5b1538a56654c096472031f1195720b18f88a4f
		#
		puts log % (0...commit_count).to_a.reverse
		
	elsif ARGV.member? "--help" then
		# Output usage information
		
		# Find the name under which this was invoked
		c = $0.split('/')[-1]
		
		usage = [
		"Dash-R v%d.%d.%d%s" % DASH_R_VERSION,
		"Usage: #{c}                  :: Print git log with revision numbers",
		"       #{c} <revno> [...]    :: Output commit(s) or range of commits",
		"                                - Accepts .. and ... for ranges)",
		"                                - Accepts negative numbers ala bzr/hg",
		"",
		"       #{c} --help           :: Show this message",
		"       #{c} --count          :: Display the number of commits",
		"",
		"`#{c} <revno>` can be used to introduce git to revision numbers:",
		"",
		"    git diff `#{c} 2..-2` ==> git diff <arcane hash>..HEAD^",
		"",
		"Non-integer tags will be left unparsed:",
		"",
		"    v0.2..-2 ==> v0.2..924b23bee3e67de575c20c70c7a89ddddb2b5c30",
		"",
		"Invalid revision numbers will be silently ignored.",
		""
		]
		
		# TODO: clean this up
		puts usage
	elsif ARGV.member? "--count"
		# Print the number of commits in the log
		puts commit_count
	else
		# get the checksums
		revs = `git log --pretty=format:'%H'`.split("\n").reverse

		ARGV.each do |revno|
			# check for ranges
			if revno =~ /[^\.](\.{2,3})[^\.]/ then
				dots = $1
				first, last = revno.split(dots).map {|rev| parse_revision rev}
				puts ((first.is_a? Fixnum) ? revs[first] : first) + dots \
				     + ((last) ? ((last.is_a? Fixnum) ? revs[last] : last) : "")
			else
				# but if there's only one...
				revno = parse_revision revno
				if revno.is_a? Fixnum then
					puts revs[revno] if revs[revno]
				else
					puts revno
				end
			end
		end
	end
end
