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
package History; # force use of fully qualified names for functions and variables.
use strict;
use Scour;
use DiffCmd;


#------------------------------------------------------------------------------
# RenderHistoryPage
# ex: return RenderHistoryPage($page_name);
# takes: $page_name
# returns: $html_page for rendering the complete history comparison selection page.
#------------------------------------------------------------------------------
sub RenderHistoryPage
{
   my $page_name = shift;
   my $checked_list = sparam("checked_list")?sparam("checked_list"):"";
   my @boxes_checked = split(":",$checked_list,2);
   my $html_page = "";
   my $old_dir = $LocalSettings::WikiOldPagesDir;
   my $oldname = $LocalSettings::WikiOldPagesDirName;
   my $line;
   my @rev_parts;
   my @revision_history;
   my @diffs = ();
   my $CHECKBOX_OFFSET = 4;  # start of first element index of checkboxes depends on elements prior to it
   my $count=$CHECKBOX_OFFSET;

   # Get array of page history meta data.
   if(@revision_history = GetPageHistory($page_name))
   {
      # Start rendering of form for displaying history and selecting for comparison via checkboxes.
      $html_page .= <<HTMLEND;
      <!--$checked_list-->
      <p><form name='form1' method='post' action='Edit.cgi'>
      <input type='hidden' name='page' value='$page_name'>            <!--element 0-->
      <input type='hidden' name='action' value='history'>             <!--element 1-->
      <input type='hidden' name='checked_list'>                       <!--element 2-->
      <input type='button' name='hbutton' value='Compare 2 Selected Versions:' onClick='javascript:this.form.checked_list.value = GetCbList(this.form);if(ChkCbList(this.form)) submit();'>                                     <!--element 3-->
     <p>
     <ul>
HTMLEND

      foreach $line (@revision_history)
      {
        if(defined($line))
        {
          @rev_parts = split(/\|/,$line);  #split the meta data into its parts...
          $rev_parts[0] =~ s/^(.*?)\.wiki.*/$1/;  # extract the file name from part 0.
          # Make a list item and checkbox with a unique name and id. We use this.  We use
          # this with javascript to alter the css style elements to give a highlighted background
          # when selected.
          $html_page .= <<HTMLEND;
          <li id="hist$count"><input type="checkbox" name="hist$count" onclick="javascript:SetCbColor(this.form);">
          <a href="View.cgi?page=$oldname:$rev_parts[0]">$rev_parts[1]</a>
          by:<i>($rev_parts[2])</i> Comments:<i>($rev_parts[3])</i>
HTMLEND
          $count++;
        }
      }
        # Write the bit of inline javascript to run the java functions.
        $html_page .= <<HTMLEND;
        </form></ul>
        <script language="javascript">
        SetCbList("$checked_list",document.form1);
        SetCbColor(document.form1);
        </script>
        <hr>
HTMLEND

      # If 2 boxes are checked then use them to perform a diff and print the diff results.
      if(@boxes_checked==2)
      {
        # Perform Diff
        my ($file1) = split(/\|/,$revision_history[$boxes_checked[1]-$CHECKBOX_OFFSET]);
        $file1 = "$old_dir/$file1";
        my ($file2) = split(/\|/,$revision_history[$boxes_checked[0]-$CHECKBOX_OFFSET]);

        $file2 = "$old_dir/$file2";
        # Execute the Diff functionality...
        @diffs = DiffCmd::diffcmd("-o",$file1,$file2);

        #$html_page.="<pre>";
        foreach $line (@diffs)
        {
          $html_page.= "<li>$line";
        }
        #$html_page.="</pre>";
      }
   }
   else
   {
      $html_page = "No history.";
   }
   return $html_page;
}
#------------------------------------------------------------------------------
# GetPageHistory
# takes: $page_name
# returns: empty array if error
# returns: @revision_history sorted newest to oldest.
#------------------------------------------------------------------------------
sub GetPageHistory
{
  my $page_name = shift;
  my $old_dir = $LocalSettings::WikiOldPagesDir;
  my $ext     = $LocalSettings::WikiFileExt;
  my $fname;
  my $buffer;
  my @empty=();
  my @revision_history=();  # empty

  # $page_name can be: Pagename, Namespace:Pagename or Namespace/Pagename.
  # if the page contains a namespace then convert the delimiter of either type.
  $page_name =~ s/\//_/g; # substitute underscore for slash
  $page_name =~ s/:/_/g; # substitute underscore for colon

  # get file names matching page_name.
  if(!opendir(DIR,$old_dir)) { return @empty; } # if can't open dir.
  my @filenames = grep { /^$page_name.*?\.$ext/} readdir(DIR);
  closedir DIR;

  my $fullfilename;

  if(@filenames)
  {
     @filenames = sort {$b cmp $a} @filenames; # sort decending;
     #push @revision_history, "$page_name  @filenames";
     foreach $fname (@filenames)
     {
        {  # local block: Load template into buffer. slurp mode.
        local $/ = undef;
        $fullfilename = "$old_dir/" . sfname($fname);
        if(!open(INFILE,'<',"$fullfilename")) { return @empty; } # if can't open file.
        $buffer = <INFILE>;
        close(INFILE);
        }
        if($buffer =~ m/.*?<!--(REVISION_TIMESTAMP:.*?)-->.*/)
        {
           $buffer =~ s/.*?<!--REVISION_TIMESTAMP:(.*?)REVISION_AUTHOR:(.*?)REVISION_COMMENT:(.*?)-->.*/$fname|$1|$2|$3/sg;
        }
        else
        {
           $buffer = "$fname";
        }
        push @revision_history,$buffer;
     }
  }
  return @revision_history;
}

#------------------------------------------------------------------------------
# NewestRevisionName - finds the newest revision of page_name within the
# "old" directory.
# returns: undef if error
# returns: newest filename if successful.
#------------------------------------------------------------------------------
sub NewestRevisionName
{
  my $page_name = shift;
  my $old_dir = $LocalSettings::WikiOldPagesDir;
  my $ext     = $LocalSettings::WikiFileExt;
  my $fname;

  if(!opendir(DIR,$old_dir)) { return undef; } # if can't open dir.
  # for the old files we prepended the directory name to the file. So we have to do that here too.
  $page_name =~ s/\//_/;
  my @filenames = grep { /^$page_name.*?\.$ext/} readdir(DIR);
  closedir DIR;
  if(!(@filenames))
  {
     return undef; # if no old files.
  }
  else
  {
     @filenames = sort {$a cmp $b} @filenames; # sort accending;
     return pop @filenames; # return the newest filename.
  }
}
#------------------------------------------------------------------------------
1;
