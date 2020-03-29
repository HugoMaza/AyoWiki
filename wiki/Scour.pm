###############################################################################
#    AyoWiki - A full featured wiki that uses minimal system resources.
#    Copyright (C) 2020 https://github.com/HugoMaza/AyoWiki
#    
#    AyoWiki was initially based on https://sourceforge.net/projects/wikilean/
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
package Scour;
use strict;
use CGI qw(:standard);
#-------------------------------
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(sparam sfname);
our $VERSION = 1.00;
#-------------------------------
# > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > >
# This module contains final check data scouring routines As such, they
# do not recover gracefully. Their purpose is that of a "circuit breaker".
#
# Any normal user data entry errors should be caught by the application long before these
# routines are called.  These are routines are for the abnormal inputs and
# are centralized here for quick updating.
# < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < <


#------------------------------------------------------------------------------
# sparam
# Use in place of the CGI module function param(). Unsafe characters are
# unceramoniously converted to underscores.
#
# ex: my $input_data = sparam("comment");
# takes: parameter name.
# returns: param value or undef if param(value) is undef.
#------------------------------------------------------------------------------
sub sparam
{
  my $SAFE_CGIPARAM_CHARS = ' a-zA-Z0-9:/_-';
  my $value = shift;
  $value =~ s/[^$SAFE_CGIPARAM_CHARS]/_/sg;  #
  my $result = param("$value");
  return (defined($result))?$result:undef;
}

#------------------------------------------------------------------------------
# sfname
# Path and extension should not be passed, only filename. Unsafe characters are
# unceramoniously converted to underscores.
#
# ex: open FILE,'>',"$path/" . sfname("comment") . ".$ext";
# takes: filename.
# returns: filename.
#------------------------------------------------------------------------------
sub sfname
{
  my $SAFE_FILENAME_CHARS = 'a-zA-Z0-9/_.-';
  my $value = shift;
  $value =~ s/[^$SAFE_FILENAME_CHARS]/_/sg;  #
  $value =~ s/\.{2}/_/sg;                    # DON'T ALLOW DOUBLE DOTS (../../passwd)
  return $value;
}
#------------------------------------------------------------------------------
1;
