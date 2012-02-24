#!/usr/bin/env perl

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

use strict;
use warnings;
use Text::ParseWords;

# Format: [major, minor, bugfix, status]
my @DASH_R_VERSION = (1,0,0,'alpha');

sub commitCount {
   open COUNT, q(git log --pretty=format:''|);

   my $count = 1;
   while (!eof COUNT) {
      <COUNT>;
      ++$count;
   }

   close COUNT;

   return $count;
}

sub inBounds {
   my ($rev, $max) = @_;
   return ($rev <= $max and -$rev <= $max + 1);
}

sub isTag {
   my $rev = shift;
   return !($rev =~ /^-{0,1}\d+$/);
}

# check if user wants the custom log format
push @ARGV, shellwords $ENV{DASH_R_OPTS}; # add in environment options
my $classic_log = (grep $_ eq '--classic', @ARGV);

# If invoked with no arguments, output the amended log.
my $numArgs = $#ARGV + 1;
if ($numArgs == 0 || ($numArgs == 1 and $classic_log)) {
   # Print the log, w/ rev numbers

   # Spin the log through the stream editor, then grab it.
   unless ($classic_log) {
      open(LOG, 'git log --graph --pretty=format:\'' .
	   'rev:     %%d => %h%n' .
	   'author:  %an <%ae>%n' .
	   'date:    %ad%n' .
	   'summary: %s%n' .
	   '\' |');
   } else {
      open(LOG, 'git log |') or die $!;
   }

   # Open the pager
   open PAGER, '| less -FSRX' or die $!;
   select PAGER;

   # Print the new log, with commit numbers, counting from zero
   #
   # Commit lines should now appear like:
   #
   #   commit 0  id: c5b1538a56654c096472031f1195720b18f88a4f
   #

   # The --classic log does not output the branch name
   unless ($classic_log) {
      my $branch = `git symbolic-ref HEAD 2> /dev/null`;
      $branch =~ s|^refs/heads/||;

      if ($branch) {
	 print "branch: $branch\n";
      }
   }

   my $count = commitCount();
   until (eof LOG) {
      my $line = <LOG>;

      if ($classic_log and $line =~ /^(commit) ([0-9a-fA-F]{40})/) {
	 printf "$1 %d  id: $2\n", --$count;
      } elsif (not $classic_log and $line =~ /rev:     %d => [0-9a-fA-F]+$/) {
	 printf $line, --$count;
      } else {
	 print $line;
      }
   }
   print "\n";

   # Close the pager
   select STDOUT;
   close PAGER;
}

# If the user asked for instruction, give them instructions.
elsif (grep $_ eq '--help', @ARGV) {
   # Output usage information

   # Find the name under which this was invoked
   my $c = (split m|/|, $0, -1)[-1];

   my @usage = (
		"Dash-R v%d.%d.%d%s",
		"Usage: $c                  :: Print log with revision numbers",
		"       $c --classic        :: Print log using classic style",
		"                                 (like normal git log + numbers)",
		"       $c <revno> [...]    :: Output commit(s) or range of commits",
		"                                 - Accepts .. and ... for ranges)",
		"                                 - Accepts negative numbers ala bzr/hg",
		"",
		"       $c --help           :: Show this message",
		"       $c --count          :: Display the number of commits",
		"",
		"`$c <revno>` can be used to introduce git to revision numbers:",
		"",
		"    git diff `$c 2..-2` ==> git diff <arcane hash>..HEAD^",
		"",
		"Non-integer tags will be left unparsed:",
		"",
		"    v0.2..-2 ==> v0.2..924b23bee3e67de575c20c70c7a89ddddb2b5c30",
		"",
		"Invalid revision numbers will be silently ignored.",
		"");

   # TODO: clean this up
   printf(shift(@usage) . "\n",
	  $DASH_R_VERSION[0], $DASH_R_VERSION[1],
	  $DASH_R_VERSION[2], $DASH_R_VERSION[3]);
   foreach my $line (@usage) {
      print "$line\n";
   }
}

# Print the number of commits in the log.
elsif (grep $_ eq '--count', @ARGV) {
   print commitCount . "\n";
}

# Get specific commit hashes.
else {
   # get the checksums
   my @revs = `git log --pretty=format:'%H'`;
   @revs = reverse @revs;

   foreach my $revno (@ARGV) {
      # check for ranges
      if ($revno =~ /(\.{2,3})/) {
	 my $dots = $1;
	 my @endpoints = split(/\.{2,3}/, $revno, 2);

	 # build the output
	 my @output = ();

	 # check the endpoints for tags/branches
	 for my $p (@endpoints) {
	    if (!defined $p or isTag $p or !inBounds $p, $#revs) {
	       push @output, $p; # apply literally
	    } else {
	       push @output, $revs[$p];
	    }
	 }
	 chomp @output;

	 print "@{[join $dots, @output]} ";
      }

      # but if there's only one...
      else {
	 if (!defined $revno or isTag $revno or !inBounds $revno, $#revs) {
	    print "$revno ";
	 } else {
	    print "$revs[$revno] ";
	 }
      }
   }
}
