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
package LocalSettings;
use strict;

# This file contains configuration settings used by the application.

our $WikiSiteCgiUrl      = "http://localhost/wiki"; # no trailing slash.
our $WikiSiteTitle       = "AyoWiki - Easy Wiki";
our $AdminEmail          = "admin\@localhost";  # used for replies to system emails. WARNING @ must be escaped!: \@
our $SkinDir             = "db/Skin";
our $SidebarPageName     = "Skin:Sidebar";
our $AdminCreateAccounts = "false";        # true = only admins can create accounts.
our $HideSessionMenu	 = "false";        # true = make application appear like its not a wiki.

our $EnableEmailNotifications = "true";                # Set to false if using windows or don't want to use.
our $EmailOption              = "sendmail";            # Currently the only option.
our $SendmailAppPath          = "/usr/bin/sendmail";   # Currently only sendmail is available (linux/unix/bsd)


our $ImageExt            = "jpg|png|gif";          # allowable image extensions separarated by |
our $DocExt              = "docx|xlsx|pptx|vsd|pdf";  # allowable doc extensions separarated by |

our $ConvFactor          = 3.62;	   # <-- Don't change this factor.
our $MaxImageSize = $ConvFactor * 1000;    # Kbytes.

our $DataFilePermissions = 0666; # Note: The Prefix 0 signifies OCTAL and must be included.
                                 # Must be octal digits and NOT a string of octal digits
                                 # RIGHT: 0666  WRONG: "0666"
our $DirectoryPermissions = 0777; # Same applies.


# Relative paths to data directories.
our $CommonJsDir       = "db/Special";
our $ImagesDir           = "db/Image";
our $WikiPagesDir        = "db";
our $WikiOldPagesDirName = "old";
our $WikiOldPagesDir     = "db/$WikiOldPagesDirName";
our $WikiFileExt         = "wiki";         # just in case you have a problem with *.wiki


our $IllegalPageNameRegEx = '[^a-zA-Z0-9:/_-]';

#------------------------------------------------------------------------------
1;
