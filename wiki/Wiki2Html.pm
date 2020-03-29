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
package Wiki2Html;  # force use of fully qualified names
use strict;
#use CGI qw(:standard); # using sparam from Scour instead.
use Scour;
use LocalSettings;
use Util;
use Session;


# Lexical variable defined in file scope space.
my @ServedPagesStack=();  # used to know when to stop transcluding.
my $before_toc_html;

sub FileNotFoundMsg
{
  my $page_name = shift;
  return "<p><h3> Oops! &quot;$page_name&quot; does not exist.</h3><p>You can create this page by clicking <a href='Edit.cgi?page=$page_name&action=new'>here</a>.";
}

#------------------------------------------------------------------------------
# WikiRender
# print Wiki2Html::WikiRender("pagename");
# takes: page_name by either parameter or by cgi
# returns: html_page for printing to client.
#------------------------------------------------------------------------------
sub WikiRender
{
  my $page_name = shift;
  my $action = sparam("action")?sparam("action"):"";
  my $html_page = "";

  if(defined($page_name)) # if page is passed as parameter then use it.
  {
    # do nothing - good
    # Only the Sidebar page is passed as a parameter to WikiRender().
  }
  elsif(sparam("page"))   # else if page is passed as cgi param then use it.
  {
    $page_name = sparam("page");
  }
  else                    # else define the default page.
  {
    $page_name = "Home";
  }

  if(defined($page_name = Util::ValidateAndFixupPageName($page_name)))
  {
     my @file_contents;
     if(@file_contents = Util::OpenFile2Array($page_name))
     {
        if( ($action eq "source") && (!($page_name =~ m/Sidebar/)) )
        {
           $html_page = ViewSource(@file_contents);
        }
        else # $action is unspecified - default wiki render to HTML.
        {
           push @ServedPagesStack,$page_name;
           $html_page = Wiki2Html($page_name,@file_contents);
           $html_page = TranscludePages($html_page);
           $html_page = TableOfContents($html_page);
           $html_page = LockImage($html_page);
        }
        # if tagged <!--PRIVATE--> and user is not signed in AND not a member
        # of any specified groups within the page...
        if(my $deny_message = Session::ViewProtected($html_page))
        {
           return "$deny_message";
        }
        else
        {
           return $html_page;
        }
    }
    else
    {
      return FileNotFoundMsg($page_name);
    }
  }
  else
  {
     return "WikiRender: Pagename is not valid.";
  }
}
#------------------------------------------------------------------------------
# Just a converter from the array to the variable really.  Does nothing to
# the wiki text.
sub ViewSource
{
  my @file_content = @_;  # parameter array containing wiki page file content.
  my $html_page = "";
  foreach (@file_content) { $html_page .= $_; }
  # return "<p>View page source<p><textarea readonly rows='25' cols='80'>$html_page</textarea>";
  return "<p>View page source<p><textarea readonly style='width: 98%; height: 400px; background-color: #F2F2F2; border-radius: 4px; color: #3D3D63; font-size: 90%;'>$html_page</textarea>";
}
#------------------------------------------------------------------------------
# takes file_content array, processes it into html and returns string containing
# html.
sub Wiki2Html
{
  my $page_name = shift;
  my @file_content = @_;  # parameter array containing wiki page file content.
  my $html_page = "";
  my $line;
  my $preformat_flag=0;
  my $dl_block_level=0;
  my $editseccnt=1;

  # We have 2 cases for section editing. Case 1:user puts in editsection tags. Case 2:section editing
  # by headers - default.  The 2 cases can not coincide. If user puts in tags then header section editing is disabled.
  my $wholepage = join(" ",@file_content);
  my $use_header_edits=1;
  if($wholepage =~ /<!--BEGINEDITSECTION-->/)
  {
    $use_header_edits=0;
  }


  # Deciding how to process (line by line or big string) is based upon:
  # 1. if formatting can go across multiple lines.
  # 2. if formatting can be done by substitution.
  # 3. if formatting requires block levels.

  #-----------------------------------------
  # FIRST PASS: Process items Line By Line.
  while (defined($line = shift @file_content))  # gets one line at a time from array.
  {
    # NOTE: The order of many of these filters is important as the more complicated
    #  patterns must be matched and substituted prior to the simplier patterns
    #  which are similar.  See the Header filters as an example: if h1 where
    #  matched prior to h2 then the results for all ==Header=='s would be <h1>=Header=</h1>.

    if($use_header_edits &&  (Session::InSession()))
    {
      # Headers (can't cross lines)
      $line =~ s/^======(.*)======/<a name='$1'><\/a><h6>$1<\/h6><p>/g;
      $line =~ s/^=====(.*)=====/<a name='$1'><\/a><h5>$1<\/h5><p>/g;
      $line =~ s/^====(.*)====/<a name='$1'><\/a><a href='Edit.cgi?page=$page_name&action=edit&sec=$editseccnt' class='editsection'>(edit)<\/a><h4>$1<\/h4><p>/g;
      $line =~ s/^===(.*)===/<a name='$1'><\/a><a href='Edit.cgi?page=$page_name&action=edit&sec=$editseccnt' class='editsection'>(edit)<\/a><h3>$1<\/h3><p>/g;
      $line =~ s/^==(.*)==/<a name='$1'><\/a><a href='Edit.cgi?page=$page_name&action=edit&sec=$editseccnt' class='editsection'>(edit)<\/a><h2>$1<\/h2><p>/g;
      $line =~ s/^=(.*)=/<a name='$1'><\/a><a href='Edit.cgi?page=$page_name&action=edit&sec=$editseccnt' class='editsection'>(edit)<\/a><h1>$1<\/h1><p>/g;
      if($line =~ /edit&sec=/)
      {
        $editseccnt++;
      }
    }
    else
    {
      # Headers (can't cross lines)
      $line =~ s/^======(.*)======/<a name='$1'><\/a><h6>$1<\/h6><p>/g;
      $line =~ s/^=====(.*)=====/<a name='$1'><\/a><h5>$1<\/h5><p>/g;
      $line =~ s/^====(.*)====/<a name='$1'><\/a><h4>$1<\/h4><p>/g;
      $line =~ s/^===(.*)===/<a name='$1'><\/a><h3>$1<\/h3><p>/g;
      $line =~ s/^==(.*)==/<a name='$1'><\/a><h2>$1<\/h2><p>/g;
      $line =~ s/^=(.*)=/<a name='$1'><\/a><h1>$1<\/h1><p>/g;
    }

    # Bullets (can't cross lines)
    $line =~ s/^\*\*\*(.*)/<ul><ul><ul><li>$1<\/ul><\/ul><\/ul>/g;
    $line =~ s/^\*\*(.*)/<ul><ul><li>$1<\/ul><\/ul>/g;
    $line =~ s/^\*(.*)/<ul><li>$1<\/ul>/g;

    # Indenting (can't cross lines)
    $line =~ s/^:::(.*)/<dl><dd><dl><dd><dl><dd>$1<\/dd><\/dl><\/dd><\/dl><\/dd><\/dl>/g;
    $line =~ s/^::(.*)/<dl><dd><dl><dd>$1<\/dd><\/dl><\/dd><\/dl>/g;
    $line =~ s/^:(.*)/<dl><dd>$1<\/dd><\/dl>/g;

    # HR (can't cross lines)
    $line =~ s/^\-\-\-\-\s*/<hr>/g;

    # External and Mailto Links (can't cross lines)
      # external relative link as (../../*)
    $line =~ s/\[(\.\.\/\.\.\/.*?)\s+(.*?)\]/<a href='$1' class='external'>$2<\/a>/g;
      # external relative link as (http://*)
    # MATCH '[http://anything anything]' OR '[http://anything anything]'
    if ( $line =~ /http\:/ ) {
        $line =~ s/(\[(http:\/\/.*?)\s+(.*?)\])|(\[(http:\/\/.*?)\])/defined($1)?"<a href='$2' class='external' target='_blank'>$3<\/a>":"<a href='$5' class='external'>$5<\/a>"/eg;
    } elsif ( $line =~ /https\:/ ) {
        $line =~ s/(\[(https:\/\/.*?)\s+(.*?)\])|(\[(http:\/\/.*?)\])/defined($1)?"<a href='$2' class='external' target='_blank'>$3<\/a>":"<a href='$5' class='external'>$5<\/a>"/eg;
    }
    $line =~ s/\[(mailto:.*?)\s+(.*?)\]/<a href='$1' class='mail'>$2<\/a>/g;

    # Category link (can't cross lines)
    #$line =~ s/\[\[Category:(.*)\]\]/<table border=1><tr><td>Category:<a href="view.cgi?page=$1">$1<\/a><\/td><\/table>/g;

    # Image link (can't cross lines)
    $line =~ s/\[\[Image:(.*?)\]\]/ImgFilter($1)/eg;

    # Doc link (can't cross lines)
    # MATCH '[[Doc:anything' UPTO ']]' OR '|anything]]'
    $line =~ s/\[\[Doc:(.*?)(\]\]|\|(.*?)\]\])/defined($3)?DocFilter("class='file'",$1,$3):DocFilter("class='file'",$1)/eg;


    # Internal link (can't cross lines)
    # MATCH '[[anything' UPTO ']]' OR '|anything]]'
    $line =~ s/\[\[(.*?)(\]\]|\|(.*?)\]\])/defined($3)?InternalLinkFilter("class='internal'",$1,$3):InternalLinkFilter("class='internal'",$1)/eg;

    # Formating (can't cross lines - Doesn't in Mediawiki so that's the standard. stop formatting at EOL)
    $line =~ s/'''g:(.*?)((''')|($))/<b><font color='green'>$1<\/font><\/b>/g;
    $line =~ s/'''b:(.*?)((''')|($))/<b><font color='blue'>$1<\/font><\/b>/g;
    $line =~ s/'''r:(.*?)((''')|($))/<b><font color='red'>$1<\/font><\/b>/g;
    $line =~ s/'''(.*?)((''')|($))/<b>$1<\/b>/g;
    $line =~ s/''(.*?)(('')|($))/<i>$1<\/i>/g;

    # Tables (line crossing NA)
    $line =~ s/^{\|/<table class='wikitable'>/g;
    $line =~ s/^\|}/<\/table>/g;
    $line =~ s/^\|-.*/<tr>/g;
    $line =~ s/^\|(.*)/<td>$1<\/td>/g;
    $line =~ s/^!(.*)/<th>$1<\/th>/g;

    # Columns  (these are simple structures for partitioning page elements only)(line crossing NA)
    $line =~ s/^__BEGINCOLUMNS__/<table class='wikicolumn'><tr><td class='wikicolumn'>/;
    $line =~ s/^__ANOTHERCOLUMN__/<\/td><td class='wikicolumn'>/;
    $line =~ s/^__ENDCOLUMNS__/<\/td><\/tr><\/table>/;

    if(!$use_header_edits)
    {
      #----------------------
      # Edit Sections
      if( ($line =~ /^(<!--BEGINEDITSECTION-->)/ )
      &&  (Session::InSession()) )
      {
        $line =~ s/^(<!--BEGINEDITSECTION-->)/<div class='editsection'>\n$1\n<a href='Edit.cgi?page=$page_name&action=edit&sec=$editseccnt' class='editsection'>(edit)<\/a><p>/;
        $editseccnt++;
      }
      if( ($line =~ /^(<!--ENDEDITSECTION-->)/ )
      &&  (Session::InSession()) )
      {
        $line =~ s/(<!--ENDEDITSECTION-->)/$1\n<\/div><p>\n\n/;
      }
      #----------------------
    }

    # Paragraph breaks
    $line =~ s/^\s*$/<p>/g; # empty line = paragraph break.

    #----------------------------------------
    # Preformatting (This needs to be last)
    if($line =~ m/^\s+(\S+)/)  #if line with text begins with spaces...
    {
      if($preformat_flag==0)   #if this is first time through...
      {
        $line =~ s/^\s+(\S+)/<pre>$1/g; #grab text prepended with <pre> tag
        $preformat_flag=1;              #set flag
      }
      else
      {
        $line =~ s/^\s+(\S+)/$1/g;  #if additional indented lines, just grab text.
      }
    }
    elsif($preformat_flag==1) #if line with text begins at beginning (no spaces) and flag is set.
    {
       $preformat_flag=0;
       $line = "</pre>" . $line; # prepend finish tag.
    }
    #----------------------------------------

    $html_page .= $line;   # append each line to one big string.
  }
  #---------------------------------------------
  # SECOND PASS: Process items as one Big String.

    $html_page =~ s/\r\n/\n/sg; # enforce unix end of line characters.
    # Remove illegal code FIRST.
    $html_page =~ s/<\s*script(.*?)<\s*\/\s*script\s*>/<!--ILLEGAL SCRIPT REMOVED-->/isg;
    # Haha. Now go insert some legal javascript.
    $html_page =~ s/__BEGINCSECTION__/<script language='javascript'>Begin_Collapsible_Section()<\/script>/g;
    $html_page =~ s/__ENDCSECTION__/<script language='javascript'>End_Collapsible_Section()<\/script>/g;

    # NOTE: THIS SHOULD BE LAST as the wiki content between the tags needs to be fully converted to HTML for Change_Sidebar_Content!
    # Sidebar content changer javascript.
    if($html_page =~ m/__BEGINSIDEBAR__(.*?)__ENDSIDEBAR__/is)
    {
      my $sidebar_html = $1;
      $sidebar_html =~ s/\n/ /g;  # remove newlines as this is a string parameter for a javascript function.
      $html_page =~ s/__BEGINSIDEBAR__(.*?)__ENDSIDEBAR__/\n<!--BEGINSIDEBAR-->\n<script language='javascript'>\nChange_Sidebar_Content(\"$sidebar_html\")\n<\/script>\n<!--ENDSIDEBAR-->\n/is;
    }
    
    # ADDED for put a text before TOC
    # Hugo Maza
    if($html_page =~ m/__BEGINBEFORETOC__(.*?)__ENDBEFORETOC__/is)
    {
      $before_toc_html = $1;
      $before_toc_html = '<!--BEGINBEFORETOC-->' . $before_toc_html . '<!--ENDBEFORETOC-->';
      $html_page =~ s/__BEGINBEFORETOC__.*?__ENDBEFORETOC__//is;
      
      # $before_toc_html =~ s/\{\{\{(.+)\}\}\}/<div class="floatNotes">$1<\/div>/;
      $before_toc_html =~ s/\{\{\{/<div class="floatNotes">/;
      $before_toc_html =~ s/\}\}\}/<\/div>/;
    }

  #----------------------------------------------
  return $html_page
}


#------------------------------------------------------------------------------
# helper function used by Wiki2Html()
sub ImgFilter
{
  my $string = shift;
  my $src="";
  my $align;
  my @attributes;
  my $namespace = undef;
  my $result;
  my $ii;

  $string =~ s/\[\[Image:(.*)\]\]/$1/g; # this is for the default Image directory.
  @attributes = split(/\|/,$string);

  # check for this form [[Image:Namespace:mypic.jpg|right]]. The Image was removed
  # above but there may be Namespace: in the first position.
  if($attributes[0] =~ m/:/)
  {
    ($namespace = $attributes[0]) =~ s/(.*?):.*/$1/;       # extract namespace.
    $attributes[0] =~ s/.*?:(.*?)/$1/;   # extract image filename.
  }

  foreach $ii (@attributes)
  {
    if($ii =~ m/.*\.[$LocalSettings::ImageExt]/) { $src=$ii; }
    if($ii =~ m/(left|middle|right)/) { $align=$ii; }
  }

  if(defined($namespace))
  {
    $result = "<img src='$LocalSettings::WikiPagesDir/$namespace/$src'";
    # if(defined($align)) {$result .= " align='$align'";}
    if(defined($align)) {
        if ( $align =~ m/(middle)/ ) {
            my $width;
            if ( defined($attributes[2]) ) {
                $width = " width: " . $attributes[2] . 'px';
            }
            $result .= " style='display: block; margin-left: auto; margin-right: auto;$width'";
        } else {
            $result .= " align='$align'";
        }
    }
    $result .= '>';
    $result = "<a href='$LocalSettings::WikiPagesDir/$namespace/$src' alt='$src' border=0>$result</a>";
  }
  else
  {
    $result = "<img src='$LocalSettings::ImagesDir/$src'";
    # if(defined($align)) {$result .= " align='$align'";}
    if(defined($align)) {
        if ( $align =~ m/(middle)/ ) {
            my $width;
            if ( defined($attributes[2]) ) {
                $width = " width: " . $attributes[2] . 'px';
            }
            $result .= " style='display: block; margin-left: auto; margin-right: auto;$width'";
        } else {
            $result .= " align='$align'";
        }
    }
    $result .= '>';
    $result = "<a href='$LocalSettings::ImagesDir/$src' alt='$src' border=0>$result</a>";
  }

  return $result;
}

#------------------------------------------------------------------------------
# helper function used by Wiki2Html() Translate colon into path slash
sub DocFilter
{
  my $class = shift;   # required param - if you don't need it pass an empty string.
  my $param1 = shift;
  my $param2 = shift;
  my $path="";
  my @dirs = ();
  my $ii;

  if($param1=~m/:/)
  {
    @dirs = split(":",$param1);

    foreach $ii (@dirs)
    {
      $path.= "/".$ii;
    }
    $path = substr($path,1);
  }
  else { $path = $param1; }

  if(!defined($param2))
  {
    $param2 = $param1;
  }

  return "<a href='$LocalSettings::WikiPagesDir\/" . $path . "' $class>$param2</a>";
}

#------------------------------------------------------------------------------
# helper function used by Wiki2Html() Translate colon into path slash
sub InternalLinkFilter
{
  my $class = shift;   # required param - if you don't need it pass an empty string.
  my $param1 = shift;
  my $param2 = shift;
  my $path="";
  my @dirs = ();
  my $ii;

  if($param1=~m/:/)
  {
    @dirs = split(":",$param1);

    foreach $ii (@dirs)
    {
      $path.= "/".$ii;
    }
    $path = substr($path,1);
  }
  else { $path = $param1; }

  if(!defined($param2))
  {
    $param2 = $param1;
  }

  return "<a href='View.cgi?page=" . $path . "' $class>$param2</a>";
}
#------------------------------------------------------------------------------
# looks for transclude strings in html_page string and transcludes as needed.
# this procedure is reentrant.
sub TranscludePages
{
  my $html_page = shift;
  $html_page =~ s/{{(.*?)\|(.*?)\|(.*?)}}/SectionTransclude(($1,$2,$3))/eg;
  $html_page =~ s/{{(.*?)}}/BasicTransclude($1)/eg;
  return $html_page;
}
#------------------------------------------------------------------------------
# includes entire page into another page.
# this procedure is reentrant.
sub BasicTransclude
{
  my $page_name = shift;
  my $html_page = "";
  my @file_contents=();


  # check all pages served - stop transclusions if endless loop setup.
  foreach (@ServedPagesStack) { if(/$page_name/) { return "$page_name"; } }
  push @ServedPagesStack,$page_name; # we are entering this page so push it on the stack.

  if((defined($page_name = Util::ValidateAndFixupPageName($page_name)))
  && (@file_contents = Util::OpenFile2Array($page_name)))
  {
    $html_page = Wiki2Html($page_name,@file_contents);
    $html_page = TranscludePages($html_page);
    pop @ServedPagesStack;  # we are returning from this page so pop it off the stack.
    return $html_page;
  }
  else
  {
    pop @ServedPagesStack;  # we are returning from this page so pop it off the stack.
    return "\n<!--BasicTransclude error-->\n";
  }

}
#------------------------------------------------------------------------------
# includes entire page into another page.
# this procedure is reentrant.
sub SectionTransclude
{
  my $page_name = shift;
  my $section = shift;
  my $stopsection = shift;
  my $taggedsection;
  my $tags;
  my $html_page = "";
  my @file_contents=();

  # check all pages served - stop transclusions if endless loop setup.
  foreach (@ServedPagesStack) { if(/$page_name/) { return "$page_name"; } }

  push @ServedPagesStack,$page_name; # we are entering this page so push it on the stack.

  if((defined($page_name = Util::ValidateAndFixupPageName($page_name)))
  && (@file_contents = Util::OpenFile2Array($page_name)))
  {
    my $wiki_page = join(";;;",@file_contents);
    my $result="";
    if($wiki_page =~ m/(=+$section=+\s*.*?)=+$stopsection=+\s*\n/s){
      $result = "$1";
    }
    my @wiki_lines = split(";;;",$result);

    $html_page = Wiki2Html($page_name,@wiki_lines);
    $html_page = TranscludePages($html_page);
    pop @ServedPagesStack;  # we are returning from this page so pop it off the stack.
    return $html_page;
  }
  else
  {
    pop @ServedPagesStack;  # we are returning from this page so pop it off the stack.
    return "\n<!--SectionTransclude error-->\n";
  }
}

#------------------------------------------------------------------------------
sub TableOfContents
{
  my $html_page = shift;
  my $not_inside_sidebar_code=1;
  if($html_page =~ /__NOTOC__/)  # if no toc is specified...
  {
    $html_page =~ s/__NOTOC__/<!--no_toc-->/;
    return $html_page;
  }
  else # go through html and find all headers and push into toc stack.
  {
     my @wiki_lines = split(/\n/,$html_page);
     my $line;
     my @toc = ();
     foreach $line (@wiki_lines)
     {
       if($line =~ m/<!--BEGINSIDEBAR-->/) { $not_inside_sidebar_code=0;}
       if($line =~ m/<!--ENDSIDEBAR-->/)   { $not_inside_sidebar_code=1;}

       if($not_inside_sidebar_code)
       {
         if($line =~ m/<h[12345]>.*?<\/h[12345]>/)
         {
           # x = string repetition operator!
           $line =~ s/.*?<h([12345])>(.*?)<\/h[12345]>.*/"<ul class='toc'>"x$1."<li class='toc'>"."\n<a class='toc' href='#".$2."'>".$2."<\/a>\n"."<\/li>"."<\/ul>"x$1/e;
           push @toc, "$line";
         }
       }
     }

     if(@toc) # if there are headers found to form a toc...
     {
        my $table_of_contents = "<table><tr><td><div class='toc'><center style='padding: 6px 0px;'>Index</center>\n";
        
        foreach $line (@toc)
        {
           $table_of_contents .= "$line\n";
        }
        $table_of_contents .= "</div></td></tr></table>\n";
        
        return  $before_toc_html . $table_of_contents . $html_page;
     }
     else # no headers were found so just pass back the html_page.
     {
        return $before_toc_html . $html_page;
     }
  }
}
#------------------------------------------------------------------------------
# renders the lock image at top of page if group protected.
sub LockImage
{
  my $html_page = shift;
  if($html_page =~ m/<!--GROUP:/)
  {
    my $image = "<img id='lockimage' src='$LocalSettings::SkinDir/lock.gif'>";
    return $image . $html_page;
  }
  return $html_page;
}
#------------------------------------------------------------------------------
# History:
# * Changed external link to allow for alias name or not.
# * Added green blue red to bold formatting options '''b:This is my blue text'''
# * Added wiki2html __BEGINSIDEBAR__ __ENDSIDEBAR__
# * Added code to TableOfContents to ignore headers inside __BEGINSIDEBAR__ __ENDSIDEBAR__
# * Added code for using <!--BEGINEDITSECTION--> and <!--ENDEDITSECTION--> tags.
#------------------------------------------------------------------------------
1;
