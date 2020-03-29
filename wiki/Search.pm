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
package Search;  # force use of fully qualified names
use strict;
#use CGI qw(:standard); # using sparam from Scour instead.
use Scour;
use LocalSettings;
use Util;
use Session;

my $SearchResults="";  # GLOBAL
my $SearchOldPages="false";
my $RootWikiDir = $LocalSettings::WikiPagesDir;


#------------------------------------------------------------------------------
# Search
# print Search::Search();
# takes: param string - search string optional
# returns: html_page for printing to client.
#------------------------------------------------------------------------------
sub Search
{
  my $string = sparam("string");
  my $searchold = sparam("searchold");
  my $namespace = sparam("namespace");
  my $html_page = "";
  my $page;
  my $image;
  my $doc;
  my $can_delete = 0;

  my $dir = $RootWikiDir; #default
  if(!defined($namespace) || $namespace eq "") { $namespace = "Main"; }
  else { $dir .= "/$namespace"; }

  if(defined($string)) # if page is passed as parameter then use it.
  {
    # perform search of pages.
    $SearchResults="<h3>Found &quot;$string&quot; in the following pages...</h3><p>";  #clear global results variable;
    $SearchOldPages= ($searchold eq "true")?"true":"false";
    WikiStringSearch($RootWikiDir,$string);
    $SearchResults .="<p>End of List";
    $html_page .= $SearchResults;
  }
  else
  {

    $html_page .= RenderSearchForm();

    #-------------------------------------------------
    if(!opendir(DIR, $RootWikiDir))
    {
       return "Find Error: can't opendir $RootWikiDir: $!";
    }
    my @namespaces = grep { /^[^\.].*?$/ && -d "$RootWikiDir/$_" } readdir(DIR);
    closedir DIR;
    #-------------------------------------------------

    $html_page .= RenderNamespaceBox(@namespaces);
    $html_page .= RenderPagenameForm();

    #-------------------------------------------------
    if(!opendir(DIR, $dir))
    {
      return "Find Error: can't opendir $dir: $!";
    }
    my @pages = grep { /^.*?\.wiki/ && -f "$dir/$_" } readdir(DIR);  #has a dot and is a file
    closedir DIR;
    foreach $page (@pages) { $page =~ s/^(.*?)\.wiki/$1/; }  # strip .wiki off name.
    #-------------------------------------------------

    #-------------------------------------------------
    if(!opendir(DIR, $dir))
    {
      return "Find Error: can't opendir $dir: $!";
    }
    my @images = grep { /^.*?\.($LocalSettings::ImageExt)/ && -f "$dir/$_" } readdir(DIR);  #has a dot and is a file
    closedir DIR;
    #-------------------------------------------------
    #-------------------------------------------------
    if(!opendir(DIR, $dir))
    {
      return "Find Error: can't opendir $dir: $!";
    }
    my @docs = grep { /^.*?\.($LocalSettings::DocExt)/ && -f "$dir/$_" } readdir(DIR);  #has a dot and is a file
    closedir DIR;
    #-------------------------------------------------

    $html_page .= "<h3>$namespace</h3><br>(existing pages)<p>\n<ul>\n";
    if($namespace eq "Main")
    {
       $namespace = "";
    }
    else
    {
       $namespace = $namespace . ":";
    }

    # check to see of user is a sysop. if so, then we will allow delete pages functionality.
 #   if(!defined(Session::GroupProtected("<!--GROUP:SYSOP-->")))  # not defined = has permission.
 #   {
 #     $can_delete = 1;
 #   }


    foreach $page (@pages)
    {
      $html_page .= "<li><a href='View.cgi?page=$namespace$page'>$page</a>\n";
 #     if($can_delete){ $html_page .= " <a href='View.cgi?page=$namespace$page'>$page</a>";}
    }
    foreach $image (@images)
    {
      $html_page .= "<li><a href='$dir/$image'>Image:$namespace$image</a>\n";
 #     if($can_delete){ $html_page .= " CAN DELETE";}
    }
    foreach $doc (@docs)
    {
      $html_page .= "<li><a href='$dir/$doc'>Doc:$namespace$doc</a>\n";
 #     if($can_delete){ $html_page .= " CAN DELETE";}
    }
    $html_page .= "</ul>\n";
  }
  return $html_page;
}
#------------------------------------------------------------------------------
# RenderNamespaceBox
# ex: $html_page .= RenderNamespaceBox(@namespaces);
# takes: @namespaces
# returns: $html for an combo box.
#------------------------------------------------------------------------------
sub RenderNamespaceBox
{
  my $prevns = sparam("namespace")?sparam("namespace"):"Main";
  my @namespaces = @_;
  my $ns;
  my $html = <<HTMLEND;
  <p>
  <h4>Find pages in namespace:</h4><br>(or enter new Pagename to create page)
  <p><form name="namespaceform" method="post" action="Find.cgi">
  Select Namespace: <select name="namespace" onchange="javascript:submit();">
    <option value='' selected>Main</option>
HTMLEND
  foreach $ns (@namespaces)
  {
    if($prevns eq $ns) {
      $html .= "    <option value='$ns' selected>$ns</option>\n" unless $ns =~ /^Special$|^Skin$/;
    }else{
      $html .= "    <option value='$ns'>$ns</option>\n" unless $ns =~ /^Special$|^Skin$/;
    }
  }
$html .= <<HTMLEND;
  </select>
  </form><p>
HTMLEND
return $html;
}

#------------------------------------------------------------------------------
# RenderPagenameForm
# ex: $html_page .= RenderPagenameForm();
# takes: nothing
# returns: $html for an edit box.
#------------------------------------------------------------------------------
sub RenderPagenameForm
{
  my $ns = sparam("namespace")?sparam("namespace").":":"";
  my $html = <<HTMLEND;
  <form name="viewform" method="post" action="View.cgi">
  Pagename: <input type="text" id="page" name="page" value="$ns">
  </form><p>
HTMLEND
return $html;
}
#------------------------------------------------------------------------------
# RenderSearchForm
# ex: $html_page .= RenderSearchForm();
# takes: nothing
# returns: $html for an edit box.
#------------------------------------------------------------------------------
sub RenderSearchForm
{
  my $html = <<HTMLEND;
  <h4>Wiki page string search:</h4><br>
  <form name="searchform" method="post" action="Find.cgi">
  Search string: <input type="text" name="string"><br>
  Include history pages <input type="checkbox" value="true" name="searchold">
  </form><p><hr><hr>
HTMLEND
return $html;
}

#------------------------------------------------------------------------------
# WikiStringSearch
# ex: $SearchResults=""; WikiStringSearch(); $html=$SearchResults;
# takes: nothing
# returns: $html of list of search results..
#------------------------------------------------------------------------------
sub WikiStringSearch
{
  my $dir = shift;
  my $string = shift;
  my @subdir =  RecursiveSearch("$dir","$string");  # process files in this directory.
  my $subd;
  foreach $subd (@subdir)  # process  each of this's subdirs...(recursively)
  {
    WikiStringSearch("$dir/$subd","$string");
  }
}
#----------------------------------------------------------------------------------
# RecursiveSearch - helper function for WikiStringSearch
#----------------------------------------------------------------------------------
sub RecursiveSearch
{
  my $dir = shift;
  my $string = shift;
  my $buffer;
  my @files;
  my $file;
  my @subdirs;
  my $exts = "wiki";
  my $tmpdir;

  # Get a list of all the files with the wiki extension.
  opendir(DIR, $dir) || die "can't opendir $dir: $!";
  @files = grep { /^.*?\.($exts)/ && -f "$dir/$_" } readdir(DIR);  #has a dot and is a file
  closedir DIR;


  foreach $file (@files)
  {
    { # local block: Load template into buffer.
    local $/ = undef;  # so we can grab whole file at once.
    if(!open(FILE,'<',"$dir/$file"))
    {
      $SearchResults .= "Skipping $dir:$file - can't open.<br>";
      next;
    }
    $buffer = <FILE>;  # get whole file.
    close(FILE);
    } # end local block.

    # if user string is found in file...
    if($buffer =~ /$string/ig)
    {
      # clean up namespace and page names so we can form the Namespace:Page format.
      $file =~ s/\.wiki//;                   # strip the extension off the filename.
      ($tmpdir = $dir) =~ s/$RootWikiDir//;  # strip the root directory off the front.
      $tmpdir =~ s/^\///;                    # strip any / off front of namespace name.
      if($tmpdir ne ""){$tmpdir .=":";}      # if not already a colon, append one.

      if(!($SearchOldPages eq "false" && $tmpdir eq "old:"))  # hide old pages results if told to.
      {
        $SearchResults .= "<li><a href='View.cgi?page=$tmpdir$file'>$tmpdir$file</a><br>";
      }
    }

  }

  # Get a list of subdirectories within this directory.
  opendir(DIR, $dir) || die "can't opendir $dir: $!";
  @subdirs = grep { /^[^\.].*?$/ && -d "$dir/$_" } readdir(DIR);  # doesn't start with dot and is a directory
  closedir DIR;

  return @subdirs;
}


#------------------------------------------------------------------------------
1;
