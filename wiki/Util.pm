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
package Util; # force use of fully qualified names for functions and variables.
use strict;
use LocalSettings;
use Scour;

#------------------------------------------------------------------------------
# OpenFile2String
#   This routine does NOT check the validity of $page_name.
#   Call ValidateAndFixupPageName prior to this function to check $page_name.
#
# ex: $file_contents = Util::OpenFile2String($page_name);
# takes: page_name
# returns: $file_contents: empty if failure.
#------------------------------------------------------------------------------
sub OpenFile2String
{
  my $page_name = shift;
  my $ext       = $LocalSettings::WikiFileExt;
  my $dir       = $LocalSettings::WikiPagesDir;
  my $line;
  my $file_contents = "";
  my $fullfilename = "$dir/" . sfname($page_name) . ".$ext";
  { # local block: Load template into buffer.
  local $/ = undef;
    if(open(INFILE,'<',"$fullfilename"))
    {
       binmode INFILE;
       $file_contents = <INFILE>;  # read whole file into string.
       close(INFILE);
    }
  }
  return $file_contents;
}
#------------------------------------------------------------------------------
# OpenFile2Array
#   This routine does NOT check the validity of $page_name.
#   Call ValidateAndFixupPageName prior to this function to check $page_name.
#
# ex: @file_contents = Util::OpenFile2Array($page_name);
# takes: page_name
# returns: @file_contents: empty if failure.
#------------------------------------------------------------------------------
sub OpenFile2Array
{
  my $page_name = shift;
  my $ext       = $LocalSettings::WikiFileExt;
  my $dir       = $LocalSettings::WikiPagesDir;
  my $line;
  my @file_contents = ();
  my $fullfilename = "$dir/" . sfname($page_name) . ".$ext";
  if(open(INFILE,'<',"$fullfilename"))
  {
     binmode INFILE;
     @file_contents = <INFILE>;  # read whole file into array.
     close(INFILE);
  }
  return @file_contents;
}
#------------------------------------------------------------------------------
# ValidateAndFixupPageName
#   This routine ONLY checks the pagename for illegal characters,
#   and replaces spaces with underscores and : with slashes so its a proper file name.
#
# ex if(defined($page_name = Util::ValidateAndFixupPageName($page_name))) {...}
# returns: undef if error with pagename. fixed up page_name if success.
#------------------------------------------------------------------------------
sub ValidateAndFixupPageName
{
  my $page_name = shift;
  $page_name =~ s/\s/_/g;  # Replace spaces in name with underscores. Spaces don't play well.
  if($page_name =~ m/$LocalSettings::IllegalPageNameRegEx/)
  {
    return undef;
  }
  $page_name =~ s/:$//g;  # check for no name after colon.
  $page_name =~ s/:/\//g; # substitute slash for colon
  return $page_name;
}

#------------------------------------------------------------------------------
# SaveEdits - This routine is used for all wiki page saves.
#  Assumes no conflicts in directory and GOOD and Fixed up page_name.
# Call ValidateAndFixupPageName() & PagenameFileConflicts() prior to this.
#
# ex: if($results = Util::SaveEdits($page_name,$wiki_text) eq "success") {...}
# takes: page_name
# takes: wiki_text
# returns: error message on failure | undef if successful
#------------------------------------------------------------------------------
sub SaveEdits
{
  my $page_name = shift;
  my $wiki_text = shift;
  my $skip_history = shift;
  my $dir     = $LocalSettings::WikiPagesDir;
  my $old_dir = $LocalSettings::WikiOldPagesDir;
  my $ext     = $LocalSettings::WikiFileExt;
  my $subdir  = "";

  # NOTE: ValidateAndFixupPageName() & PagenameFileConflicts() must be called
  # prior to this function.

  # Textarea forms use CRNL even in multipart for separates. rid any CR
  $wiki_text =~ s/\r//sg;  # binmode eol tweek, this fixes the CRNLs appearing.

  # Check again only for a non-existent directory.
  if(PagenameFileConflicts($page_name)==1)
  {
     ($subdir) = split(/\//, $page_name);
     if(!mkdir "$dir/$subdir")
     {
        return "Could not create directory for: $dir/$subdir";
     }
     # if chmod doesn't success there isn't much that can be done about it. Its not fatal.
     chmod $LocalSettings::DirectoryPermissions, "$dir/$subdir";
  }

  # We want to save the edit log comments with the old_wiki_text but we want to strip
  # them out of the current wiki_text...
  my $old_wiki_text = $wiki_text;                     # make a copy.
  $wiki_text =~ s/\n<!--REVISION_TIMESTAMP:.*?-->//sg;  # strip out log comments from current.

  my $fullfilename = "$dir/" . sfname($page_name) . ".$ext";

  if(!open(OUTFILE,'>',"$fullfilename"))
  {
    close(OUTFILE);
    return "<h3>save error: could not open file: $page_name</h3>";
  }
  binmode OUTFILE;
  print OUTFILE "$wiki_text";
  close(OUTFILE);
  # if chmod doesn't success there isn't much that can be done about it. Its not fatal.
  chmod $LocalSettings::DataFilePermissions, "$dir/$page_name.$ext";

  if($skip_history ne "true")
  {
    # Save as old file right now. So the "previous" page is always 1 older than whats
    # in old dir. but we only have to save the same file twice instead of a read then write.
    my $ts = TimeStamp();
    # For the old file, substitute the / with and underscore because we are not making any
    # subdirectories for old files.
    $page_name =~ s/\//_/g; # substitute underscore for slash

    $fullfilename = "$old_dir/" . sfname("$page_name$ts") . ".$ext";

    if(!open(OUTFILE2,'>',"$fullfilename"))
    {
      close(OUTFILE2);
      return "<h3>save error (old): could not open file: $page_name</h3>";
    }
    binmode OUTFILE2;
    print OUTFILE2 "$old_wiki_text";
    close(OUTFILE2);
    # if chmod doesn't success there isn't much that can be done about it. Its not fatal.
    chmod $LocalSettings::DataFilePermissions, "$old_dir/$page_name$ts.$ext";
  }
  return undef;
}
#------------------------------------------------------------------------------
# PagenameFileConflicts
#  Assumes page_name itself is GOOD. Call ValidateAndFixupPageName prior to this.
#  Checks for conflicts with file directory. Use prior to saving.
# if(Util::PagenameFileConflicts($page_name)) {...}
# returns:
# 0 = no conflicts
# 1 = non-existant directory - nmn-fatal.
# 2 = page name collides with existing directory (namespace) name (namespace:pagename)
# 3 = directory (namespace) name (namespace:pagename) collides with existing page name
# 4 = attempt to create sub-subdirectory -fatal.
# my @pagename_file_conflict_error = qw(noError NonExistentDirectory DirNameCollision PageCollision DirectoryDepthError);
#------------------------------------------------------------------------------
sub PagenameFileConflicts
{
  my $page_name = shift;
  my $subdir;
  my $ext       = $LocalSettings::WikiFileExt;
  my $dir       = $LocalSettings::WikiPagesDir;
  my $result=0;

  # A file and directory with the same name can not coexist.
  if($page_name =~ m/\//) # if directory is specified... Something/Else
  {
     # if page is "Hello/World/One2Many" .... ( but assign to $subdir just in case its not...
     if( (($subdir)= (my @temp = split(/\//,$page_name))) > 2 )
     {
        $result = 4;
     }
     elsif(-e "$dir/$subdir.$ext" || -e "$dir/$subdir")  # if exists as either a file or a directory...
     {
        if(-d "$dir/$subdir")  # if is a directory...
        {
           # good to go.  :-) able to create file in existing directory.
           $result=0;
        }
        else
        {
           # oops, its another page not a directory ;-(
           $result=3;
        }
     }
     else
     {
        # good to go, almost. ;-) able to create a new directory first and then the page within it.
        $result = 1;
     }
  }
  else # Just a single pagename is specified.
  {
     if(-d "$dir/$page_name")  # if exists as a directory...
     {
       # oops, its a directory, can't make a page in main space. ;-(
       $result = 2;
     }
     else
     {
        # good to go.  :-) able to create file in main wiki space.
        $result = 0;
     }
  }
  return $result;
}

#------------------------------------------------------------------------------
# TimeStamp - returns format "YYYYMMDDHHMMSS"
#------------------------------------------------------------------------------
sub TimeStamp
{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year += 1900;
  $mon +=1;
  $mon = $mon<10?"0".$mon:$mon;
  $mday = $mday<10?"0".$mday:$mday;
  $hour = $hour<10?"0".$hour:$hour;
  $min = $min<10?"0".$min:$min;
  $sec = $sec<10?"0".$sec:$sec;
  return "$year$mon$mday$hour$min$sec";
}
#------------------------------------------------------------------------------
# PrettyTimeStamp - returns format "DD-MMM-YYYY HH:MM:SS"
#------------------------------------------------------------------------------
sub PrettyTimeStamp
{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year += 1900;
  #$mon +=1;
  #$mon = $mon<10?"0".$mon:$mon;
  my @month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  $mday = $mday<10?"0".$mday:$mday;
  $hour = $hour<10?"0".$hour:$hour;
  $min = $min<10?"0".$min:$min;
  $sec = $sec<10?"0".$sec:$sec;
  return "$mday-$month[$mon]-$year $hour:$min:$sec";
}


#------------------------------------------------------------------------------
1;
