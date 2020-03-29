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
package Upload; # force use of fully qualified names for functions and variables.
use strict;
use CGI qw(:standard);
use Scour;
use Session;


#------------------------------------------------------------------------------
# Upload
# ex: print Upload();
# takes: nothing
# takes: action as cgi param:
# returns: $html_page
#------------------------------------------------------------------------------
sub Upload
{
  my $page_name = sparam("page")?sparam("page"):undef;
  my $action = sparam("action")?sparam("action"):undef;
  my $nsdir = $LocalSettings::WikiPagesDir;
  my $dir = $LocalSettings::WikiPagesDir;
  my $html_page = "";

  if(!defined(Session::InSession() ))
  {
    return "<b>You are not logged in</b>";
  }


  if(!defined($action))
  {
    #-------------------------------------------------
    if(!opendir(DIR, $nsdir))
    {
       return "Find Error: can't opendir $nsdir: $!";
    }
    my @namespaces = grep { /^[^\.].*?$/ && -d "$nsdir/$_" } readdir(DIR);
    closedir DIR;
    #-------------------------------------------------

    $html_page .= RenderUploadForm(@namespaces);

  }
  elsif($action eq "upload")
  {
     my $namespace = sparam("namespace");
     my $dir = $LocalSettings::WikiPagesDir;
     my $file = sparam("file");
     my $filename = ucfirst lc sparam("filename");
     my $ext1 = $file;
     my $ext2 = $filename;
     $ext1 =~ s/.*?\.(.*?)/$1/;
     $ext2 =~ s/.*?\.(.*?)/$1/;
     $ext1 = lc $ext1;
     if( !($ext1 =~ m/($LocalSettings::ImageExt)/)
     &&  !($ext1 =~ m/($LocalSettings::DocExt)/)
     )
     {
       return "<b>Error: Allowable file types are $LocalSettings::ImageExt and $LocalSettings::DocExt</b>";
     }
     if($ext1 ne $ext2)
     {
       return "<b>Error: File extensions of source and destination names must match.</b>";
     }
     if( ($ext1 =~ m/($LocalSettings::DocExt)/) && ($namespace eq "Image"))
     {
       return "<b>Error: You can't save documents in the Image area. </b>";
     }


     my $handle;
     my $count=0;
     my $query = new CGI;
     $handle = $query->upload("file");
     if(open(UL,">","$dir/$namespace/$filename"))
     {
        binmode UL;
        while ( <$handle> )
        {
           print UL;
           $count++;
           if($count > $LocalSettings::MaxImageSize)
           {
             close UL;
             chmod $LocalSettings::DataFilePermissions, "$dir/$namespace/$filename"; # there is a partial file there.
             return "<b> File exceeds ". int($LocalSettings::MaxImageSize/$LocalSettings::ConvFactor)  ." Kbyte limit.</b>";
           }
        }
        close UL;
        chmod $LocalSettings::DataFilePermissions, "$dir/$namespace/$filename";
        if($namespace eq "Image")
        {
          $html_page = "Image uploaded as <a href='$dir/$namespace/$filename'>[[$namespace:$filename]]</a>";
        }
        else
        {

          if($ext1 =~ m/($LocalSettings::ImageExt)/)
          {
            $html_page = "Image uploaded as <a href='$dir/$namespace/$filename'>[[Image:$namespace:$filename]]</a>";
          }
          elsif($ext1 =~ m/($LocalSettings::DocExt)/)
          {
            $html_page = "Document uploaded as <a href='$dir/$namespace/$filename'>[[Doc:$namespace:$filename]]</a>";
          }
        }
        $html_page .= " (" .  int($count/$LocalSettings::ConvFactor) . " Kbytes)"
     }
     else
     {
        $html_page = "Could not open $filename $! (make sure you selected an area to upload into)";
     }
  }
  return $html_page;
}
#------------------------------------------------------------------------------
# RenderUploadForm
# ex: $html_page .= RenderNamespaceBox(@namespaces);
# takes: @namespaces
# returns: $html for an combo box.
#------------------------------------------------------------------------------
sub RenderUploadForm
{
  my $prevns = sparam("namespace")?sparam("namespace"):"Main";
  my @namespaces = @_;
  my $ns;
  my $html = <<HTMLEND;
  <h3>Upload Image</h3><p>
  <p>
  <script language="javascript">
    function ns2fn() {
      var str = new String(document.getElementById("file").value);
      str = str.replace(\/.*[\\/\\\\](.*?)\$\/g,"\$1");
      str = str.charAt(0).toUpperCase()+str.substr(1).toLowerCase();
      document.getElementById("filename").value=str;
    }
  </script>
  <form name="form1" method="post" action="Upload.cgi"  enctype="multipart/form-data">
  Image to upload: <input id="file" type="file" name="file" size=50 onChange="javascript:ns2fn();"><p>
  Which area to upload image:
  <select name="namespace">
    <option value='zzzz' selected>Select</option>
HTMLEND
  foreach $ns (@namespaces)
  {
     # if this user has permission to this namespace, then list it.
     if(!defined(Session::NamespaceProtected($ns.":DummyPage")))
     {
       $html .= "    <option value='$ns'>$ns</option>\n";
     }
  }
$html .= <<HTMLEND;
  </select>
  <p>
  Filename to save as: <input id="filename" type="text" name="filename" size=30> <i>(filenames are case sensitive)</i><p>
  <input type="hidden" name="action" value="upload">
  <input type="submit" name="submit" value="Submit" >
  </form><p>
  Warning: This will overwrite any existing files without notice. <br>
  If in doubt, use the "find" feature to look for existing filenames.<p>
HTMLEND
 $html .= int($LocalSettings::MaxImageSize/$LocalSettings::ConvFactor) . " Kbyte size limit.";
return $html;
}


#------------------------------------------------------------------------------
1;
