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
package Editor; # force use of fully qualified names for functions and variables.
use strict;
#use CGI qw(:standard); # using sparam from Scour instead.
use Scour;
use Session;
use Util;
use Wiki2Html;
use History;

#------------------------------------------------------------------------------
# WikiEdit
# ex: print WikiEdit();
# takes: page_name as cgi param
# takes: action as cgi param: empty(default to edit given page)|preview|save|new
# returns: $html_page with edit box and/or preview text or message from save.
#------------------------------------------------------------------------------
sub WikiEdit
{
  my $page_name = sparam("page")?sparam("page"):undef;
  my $action = sparam("action")?sparam("action"):undef;

  my $old_dir = $LocalSettings::WikiOldPagesDir;

  my @pagename_file_conflict_error =
  ("noError",
   "Non-Existent Directory",
   "Error: This pagename conflicts with an existing defined namespace.",
   "Error: This namespace (i.e. Namespace:PageName) conflicts with an existing defined page.",
   "Error: Can't use more than one level of namespaces (i.e. Namespace:Pagename = correct."
  );
  my $username;

  if(!defined($action)) { return "WikiEdit Error: No Action Command"; }

  if(defined($page_name = Util::ValidateAndFixupPageName($page_name)))
  {
     if((my $errnum = Util::PagenameFileConflicts($page_name)) > 1)
     {  # >1: its ok if non-existent directory, it will be created in Util::SaveEdits()
       return "<p><b>" . $pagename_file_conflict_error[$errnum] . "</b>";
     }
  }
  else
  {
    return "WikiEdit: Pagename is not valid.";
  }

  if(!defined($username = Session::InSession() ))
  {
    return "<b>You are not logged in. Click <a href='Login.cgi?action=login&prepage=$page_name'>here</a> to login.</b>";
  }

  #***************************************
  # At this point session is authenticated
  # and pagename and directory check are
  # good.
  #***************************************

  my @file_contents = ();
  my $error_code;
  my $html_page = "";
  my $deny_message;

  # used in save and preview:
  my $wiki_text = sparam("wikitext")?sparam("wikitext"):"";
  my $comment = sparam("comment")?sparam("comment"):"";
  my $skip_history = sparam("skip_history")?sparam("skip_history"):"";
  my $section = sparam("sec")?sparam("sec"):undef;
  my $before = sparam("before")?sparam("before"):"";
  my $after = sparam("after")?sparam("after"):"";
  my $part1="";
  my $part2="";
  my $part3="";
  my $partnum;
  my @secparts;

  # This is for fixing up the ENDEDITSECTION NL user mistakes. User may remove last NL without realizing that
  # when it is appended by 'after', the first wiki in 'after' may not work as it is not at the start of a line.
  # if there is not a NL at the end of wiki_text AND (after starts with ENDEDITSECTION tag OR header)...
  if(($wiki_text !~ /\n$/s) && (($after =~ /^<!--ENDEDITSECTION-->/)||($after =~ /^=/)))
  {
    $wiki_text .= "\n";  # Add NL at end. User removed NL at end without knowing consequences.
  }
  $wiki_text = $before . $wiki_text . $after;

  #
  # Parse the ACTION to setup $wiki_text in various ways.
  #

  # EDIT: This called from an outside page as a link with only the EDIT action and page_name.
  # The text is loaded from the cooresponding wiki file into the $wiki_text variable.
  if($action eq "edit")
  {
     if(@file_contents = Util::OpenFile2Array($page_name))
     {
        foreach (@file_contents) { $wiki_text .= $_; }  # convert to one big string
     }
     else
     {
       return "WikiEdit Error: Can not open file: $page_name";  #abort
     }
  }
  # PREVIEW: This is called from this editor form itself with $wiki_text coming back in
  # from the edit box (loop-back) to be previewed and put back into this next rendering of the form.
  elsif($action eq "preview")
  {

     @file_contents = split("\n",$wiki_text);  # convert to an array for the Html2Wiki function.
  }
  # SAVE: This is called from this editor form itself with $wiki_text coming back in
  # from the edit box (loop-back) to be saved by providing it as a parameter to the SaveEdit() function.
  elsif($action eq "save")
  {
     # Check that the version we are editing is still the latest "old" version.
     # We are checking for 2 people editing at the same time.
     # Get the newest revision of this page in the old directory.
     # get the newest_revision value that was passed by the form.
     my $newest_revision = sparam("newest_revision")?sparam("newest_revision"):"NotAvailable";

     if(defined(my $newest_rev = History::NewestRevisionName($page_name)))
     {

        if($newest_rev ne $newest_revision)
        {
          # Then we have a problem...someone else saved another copy before we did
          # while we were still editing!!
          return "<h2>ERROR! Someone else has been simultaneously editing this page!</h2> <p><b> You can not save your edits.</b>  <ol><li>Click the BACK button of your browser.<li>Put the cursor inside the edit box and hit CTRL-A to highlight all, then CTRL-C to copy.<li>Refresh the page; put the cursor at the bottom of the edit box and hit CTRL-V to paste.<li>You'll have to re-edit the page.<li>If its a very large page you may want to paste to NotePad instead.</ol>";
        }
     }

     # Make a revision log entry as an html comment and append it to the end of the $wiki_text.
     # This will be saved in the history file but will be stripped out of the current file
     # by SaveEdits() (SaveEdits saves both current and history files).
     my $ts = Util::PrettyTimeStamp();
     $wiki_text .= "\n<!--REVISION_TIMESTAMP:$ts REVISION_AUTHOR:$username REVISION_COMMENT:$comment-->";
     my $err_message = Util::SaveEdits($page_name,$wiki_text,$skip_history);
     if(defined($err_message))
     {
        $html_page .= $err_message;
     }
     else # success
     {
         return "<script language='javascript'>document.location='View.cgi?page=$page_name'</script>";
     }
  }
  # EDIT: This called from an outside page as a link with only the NEW action and page_name.
  # $wiki_text is cleared as it is a brand new page.
  elsif($action eq "new")
  {
    $wiki_text = ""; # don't need to do anything for new page...
  }
  # HISTORY: This called from an outside page as a link with only the HISTORY action and page_name.
  # This is merely a jumpoff-point to the RenderHistoryPage() function as this function has nothing to do
  # with editing the wiki.  So, $wiki_text is a don't care.
  elsif($action eq "history")
  {
    return History::RenderHistoryPage($page_name);
  }

  #
  # Now that $wiki_text is properly setup, we can proceed with invoking the actual edit box...
  #

  # Before allowing editing, however, check for group protection
  # tags in wiki text. <!--GROUP:CafeGroup-->
  if(defined($deny_message = Session::GroupProtected($wiki_text)))
  {
    # Sorry, but you can't edit this page!
    $html_page = "<p><p><b>$deny_message</b>"; # Error or Group restricted.
  }
  elsif(defined($deny_message = Session::NamespaceProtected($page_name)))
  {
    # Sorry, but you can't edit this page!
    $html_page = "<p><p><b>$deny_message</b>"; # Error or Namespace restricted.
  }
  else  # Ok, Bring up the edit box and preview page text if it was requested...
  {
    if($action eq "preview")
    {
      $html_page .= "<i><font color='red'>Preview warning: This page has not been saved.</font></i><p>";
      $html_page .= Wiki2Html::Wiki2Html($page_name,@file_contents);
      $html_page = Wiki2Html::TranscludePages($html_page);
    }

    if(defined($section)) # if section is defined then only show edit content for that section.
    {
      # We have 2 cases for section editing. Case 1:user puts in editsection tags. Case 2:section editing
      # by headers - default.  The 2 cases can not coincide. If user puts in tags then header section editing is disabled.
      if($wiki_text =~ /<!--BEGINEDITSECTION-->/) # if User is using editsection tags...
      {
        # We add special split char because the split removes the split character.
        $wiki_text =~ s/<!--BEGINEDITSECTION-->/<!--BEGINEDITSECTION-->##SPLITHERE##/g; # add special split char after.
        $wiki_text =~ s/<!--ENDEDITSECTION-->/##SPLITHERE##<!--ENDEDITSECTION-->/g;     # add special split char before.
        @secparts = split(/##SPLITHERE##/,$wiki_text); # who knows how many parts this will be? many.
        #-----------------------------------------------
        # arrange into only 3 parts.
        # (0)b(1)ab(2)a(3)b(4)a(5)
        # (0)h(1)h(2)h(3)h(4)h(5)
        for($partnum=0;$partnum<$section*2-1;$partnum++)
        {
          $part1 = join("",$part1,$secparts[$partnum]);
        }

        $part2 = $secparts[$section*2-1];

        for($partnum=$section*2;$partnum<(@secparts);$partnum++)
        {
          $part3 = join("",$part3,$secparts[$partnum]);
        }
        #-----------------------------------------------
      }
      else
      {
        # We add special split char because the split removes the split character.
        $wiki_text =~ s/^(={1,4}[^=]+?={1,4}[^=])/##SPLITHERE##\n$1/mg; # add special split char before.
        @secparts = split(/##SPLITHERE##\n/,$wiki_text); # who knows how many parts this will be? many.
        #-----------------------------------------------
        # arrange into only 3 parts.
        # (0)b(1)ab(2)a(3)b(4)a(5)
        # (0)h(1)h(2)h(3)h(4)h(5)
        for($partnum=0;$partnum<$section;$partnum++)
        {
          $part1 = join("",$part1,$secparts[$partnum]);
        }

        $part2 = $secparts[$section];

        for($partnum=$section+1;$partnum<(@secparts);$partnum++)
        {
          $part3 = join("",$part3,$secparts[$partnum]);
        }
        #-----------------------------------------------
      }

      $html_page .= RenderEditbox($page_name,$part2,$comment,$skip_history,$part1,$part3,$section);
    }
    else # otherwise edit whole page
    {
      $html_page .= RenderEditbox($page_name,$wiki_text,$comment,$skip_history,"","","");
    }
  }
  return $html_page;
}

#------------------------------------------------------------------------------
# RenderEditbox
# ex: $html_page .= RenderEditbox($page_name,$wiki_text);
# takes: $page_name
# takes: $wiki_text
# returns: $html for an edit box.
#------------------------------------------------------------------------------
sub RenderEditbox
{
  my $page_name = shift;
  my $wiki_text = shift;
  my $comment = shift;
  my $skip_history = shift;
  my $before = shift;
  my $after = shift;
  my $section = shift;
  my $checked = ($skip_history eq "true")?"checked":"";
  my $newest_revision = History::NewestRevisionName($page_name);
  $newest_revision = defined($newest_revision)?$newest_revision:"";
  my $html = <<HTMLEND;
  <p>Edit page: <b>$page_name</b><p>
  <form name="editform" method="post" action="Edit.cgi" enctype="multipart/form-data">
  <input type='hidden' name="page" value="$page_name">
  <input type='hidden' name="action">
  <input type='hidden' name="newest_revision" value="$newest_revision">
  <textarea name="before" style="visibility: hidden">$before</textarea>
  
  <div style="padding: 10px 0 0 0; background-color: #EEEEEE;">
  <textarea id="wiki" tabindex='1' accesskey="," name="wikitext" style='width: 98%; height: 400px; background-color: #FDFDFD; border-radius: 4px; color: #171739; font-size: 90%;'>$wiki_text</textarea><br>
  </div>
  
  <textarea name="after" style="visibility: hidden">$after</textarea>
  <input type='hidden' name="sec"  value="$section"><br>
  Comment: <input type='text' maxlength=120 size=70 name="comment" value="$comment"><br><br>
  Minor Edits:<input type='checkbox' name="skip_history" value="true" $checked> (<i>Don't save a copy of your edits to history.</i>)<br><br>
  <input type="button" value="Save" onClick="this.form.action.value='save';this.form.submit();"> &nbsp; 
  <input type="button" value="Preview" onClick="this.form.action.value='preview';this.form.submit();"> &nbsp; 
  <a href="javascript:document.location='View.cgi?page=$page_name';">Cancel</a>
  </form>
  <script language="javascript">
    \$(document).ready(function()	{
        \$('\#wiki').markItUp(myWikiSettings);
    });
  </script>
HTMLEND
return $html;
}

#------------------------------------------------------------------------------
# History:
# * Added code for using <!--BEGINEDITSECTION--> and <!--ENDEDITSECTION--> tags.
#   These tags are suppose to start at beginning of newline with nothing else.
#   Added fixups for NL oddities caused by text being edited to end without NL
#   or begin without NL.
# * Added code for Header Section editing.
#------------------------------------------------------------------------------
1;
