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
my @DASH_R_VERSION = (2,0,0,'-alpha.1');

sub commitCount {
   my $branch = shift;
   my $count  = `git rev-list $branch | wc -l`;
   chomp $count;
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

sub thisBranch {
   my $branch = `git symbolic-ref HEAD 2> /dev/null`;
   $branch =~ s|^refs/heads/||;
   chomp $branch;
   return $branch;
}

# check if user wants the custom log format
push @ARGV, shellwords $ENV{DASH_R_OPTS}; # add in environment options
my $all = (grep $_ eq '--all', @ARGV) ? '--all' : '';

# If invoked with no arguments, output the amended log.
my $numArgs = $#ARGV + 1;
if ($numArgs == 0 || ($numArgs == 1 and $all)) {
   open(LOG, 'git log ' . ($all ? '--all' : '') .
        ' --graph --pretty=format:\'' .
        'rev:     %%d => %h %d%n' .
        'author:  %an <%ae>%n' .
        'date:    %ad%n' .
        'summary: %s%n' .
        '\' |') or die $!;

   # Open the pager
   $ENV{LESS} = $ENV{LESS} || 'FSRX';
   open PAGER, '| less' or die $!;
   select PAGER;

   # Print the log, w/ rev numbers
   print "branch: " . thisBranch . "\n\n" unless ($all);
   my $count = commitCount($all or thisBranch);
   until (eof LOG) {
      my $line = <LOG>;

      if ($line =~ /rev:     %d => .+$/) {
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

   my $usage =
qq|Dash-R v%d.%d.%d%s
Usage: $c                  :: Print log with revision numbers
       $c --all            :: Work with all branches (like hg)
       $c <revno> [...]    :: Output commit(s) or range of commits
                                 - Accepts .. and ... for ranges)
                                 - Accepts negative numbers ala bzr/hg

       $c --help           :: Show this message
       $c --count          :: Display the number of commits

`$c <revno>` can be used to introduce git to revision numbers:

    git diff `$c 2..-2` ==> git diff <arcane hash>..HEAD^

Non-integer tags will be left unparsed:

    v0.2..-2 ==> v0.2..924b23bee3e67de575c20c70c7a89ddddb2b5c30

Invalid revision numbers will be silently ignored.
|;

   # TODO: clean this up
   printf($usage, $DASH_R_VERSION[0], $DASH_R_VERSION[1], $DASH_R_VERSION[2],
                  $DASH_R_VERSION[3]);
}

# Print the number of commits in the log.
elsif (grep $_ eq '--count', @ARGV) {
   print commitCount($all or thisBranch) . "\n";
}

# Get specific commit hashes.
else {
   # get the checksums
   my @revs = `git log $all --pretty=format:'%h'`;
   @revs = reverse @revs;
   chomp @revs;

   foreach my $revno (@ARGV) {
      # prevent options from being interpreted as tags
      next if ($revno =~ /^\-/);
      
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
