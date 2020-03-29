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
package Session;  # force use of fully qualified names
use strict;
#use CGI qw(:standard); # using sparam from Scour instead.
use Scour;
use LocalSettings;
use Util;
use Mailer;

my $LoginTemplate = "Login.cgi";
my $UserCookie = "WLuser";
# Note: the session cookie is just the crypted password
my $CryptedPWCookie = "WLsession";
my $CookieHours = 9;

my $PWFile = "$LocalSettings::WikiPagesDir/Special/Users.wiki";
my $DELIM="::";
my $GroupsFile = "$LocalSettings::WikiPagesDir/Special/Groups.wiki";
my $NamespacesFile = "$LocalSettings::WikiPagesDir/Special/Namespaces.wiki";

#------------------------------------------------------------------------------
# LoginManager
# ex: print Session::LoginManager();
# takes: prepage as cgi param
# takes: action as cgi param
# returns: $html_text to be printed to the client.
#------------------------------------------------------------------------------
sub LoginManager
{
  my $html_text = "<b>Login error:(LoginManager) no case taken.</b>";
  my $line = "";
  my $line2 = "";
  my $prepage = sparam("prepage")?sparam("prepage"):"Home"; # previous page for redirection back.
  my $action = sparam("action")?sparam("action"):"";
  my @array;
  my $retval;
  my $pw;
  my $emsg="";

  if($action eq "logout")  # LOG OUT
  {
    $html_text = DeleteCookie("$UserCookie");
    $html_text .= DeleteCookie("$CryptedPWCookie");
    $html_text .= "<p>You are now logged out. Return to <a href='View.cgi?page=$prepage'>$prepage</a>.<p> ";
    $html_text .= "<script>window.location.href = 'View.cgi?page=$prepage';</script>";
  }
  elsif($action eq "login")
  {
    $html_text = RenderLogin($prepage);
  }
  elsif($action eq "new")
  {
    if(!defined(GroupProtected("<!--GROUP:SYSOP-->")))  # not defined = has permission.
    {
      $html_text = RenderAccountForm("new",$prepage);
    }
    elsif($LocalSettings::AdminCreateAccounts eq "false")
    {
      $html_text = RenderAccountForm("new",$prepage);
    }
    else
    {
      $html_text = "This feature is disabled. Only Admins can create accounts.";
    }
  }
  elsif($action eq "update")
  {
    $html_text = RenderAccountForm("update",$prepage);
  }
  elsif($action eq "newaccount")
  {
    $array[0] = sparam("username");
    $array[1] = crypt($pw = sparam("password"),sparam("username"));
    $array[2] = sparam("email");
    if(FindUser(sparam("username")))
    {
       $html_text = "Username is not available.";
    }
    else
    {
      if(defined(SaveUserProfile("new",@array)))
      {
        $html_text = DeleteCookie("$UserCookie");
        $html_text .= DeleteCookie("$CryptedPWCookie");
        $html_text .= "New user profile saved. You can now <a href='Login.cgi?action=login&prepage=$prepage'>login</a>.";
        if(defined($retval=Mailer::MailMessage($array[2],"Your $LocalSettings::WikiSiteTitle account has been created.","Username: $array[0]\nPassword: $pw\nEmail: $array[2]\n")))
        {
          $html_text .= $retval;
        }
      }
      else
      {
        $html_text = DeleteCookie("$UserCookie");
        $html_text .= DeleteCookie("$CryptedPWCookie");
        $html_text .= "SaveUserProfile Failed.";
      }
    }
  }
  elsif($action eq "updateaccount")
  {
    if(@array = FindUser(sparam("username")))
    {
      $line = join(";;",@array);
      $array[0] = ($array[0] eq sparam("username"))?$array[0]:sparam("username");
      if($array[1] eq sparam("password")) { $pw = "(not changed)"; }
      else { $array[1] = crypt($pw = sparam("password"),sparam("username")); }
      $array[2] = ($array[2] eq sparam("email"))?$array[2]:sparam("email");
      #$line2 = join(";;",@array);
      #$result ="OLD:$line<br>NEW:$line2";
      if(defined(SaveUserProfile("update",@array)))
      {
        $html_text = DeleteCookie("$UserCookie");
        $html_text .= DeleteCookie("$CryptedPWCookie");
        $html_text .= "User profile updated. You must now <a href='Login.cgi?action=login&prepage=$prepage'>re-login</a>.";
        if(defined($retval=Mailer::MailMessage($array[2],"Your $LocalSettings::WikiSiteTitle account has been updated.","Username: $array[0]\nPassword: $pw\nEmail: $array[2]\n")))
        {
          $html_text .= $retval;
        }
      }
      else
      {
        $html_text = DeleteCookie("$UserCookie");
        $html_text .= DeleteCookie("$CryptedPWCookie");
        $html_text .= "SaveUserProfile Failed.";
      }

    }
  }
  #------------------Email Reset funcionality-----------------------------
  elsif($action eq "forgotpw")
  {
    $html_text = RenderPasswordReset($prepage);
  }
  elsif($action eq "mailpw")
  {
    if(@array = FindUser(sparam("username")))
    {
      my $newpw="";
      my $n;
      for($n=0;$n<6;$n++)
      {
        $newpw .= chr(97+rand(25)); # 97 is ascii lowercase 'a'. Generate 6 char random password.
      }
      $array[1] = crypt($newpw,sparam("username"));
      $line = join(";;",@array);
      $emsg = "You (or someone posing as you) requested a password reset for: $array[0]. \nClick on this link to activate or ignore this email to continue using old password.\n\nNew Password: $newpw\n\n $LocalSettings::WikiSiteCgiUrl/Login.cgi?action=resetpw&username=$array[0]&pw=$array[1]\n ";
      if(defined($retval=Mailer::MailMessage($array[2],"Your $LocalSettings::WikiSiteTitle password activation is here.","$emsg")))
      {
        $html_text = $retval;
      }
      else
      {
        $html_text = "Email activation sent. Check your email";
      }
    }
  }
  elsif($action eq "resetpw")
  {
    if(@array = FindUser(sparam("username")))
    {
      $array[1] = sparam("pw");
      $line = join(";;",@array);
      if(defined(SaveUserProfile("update",@array)))
      {
        $html_text = DeleteCookie("$UserCookie");
        $html_text .= DeleteCookie("$CryptedPWCookie");
        $html_text .= "User profile updated. You must now <a href='Login.cgi?action=login&prepage=$prepage'>re-login</a> with the new password emailed to you.";
      }
      else
      {
        $html_text = DeleteCookie("$UserCookie");
        $html_text .= DeleteCookie("$CryptedPWCookie");
        $html_text .= "SaveUserProfile Failed. Password Reset Failed.";
      }
    }
  }
  #-----------------------------------------------
  elsif($action eq "authenticate")
  {
    $html_text = AuthenticateCgiParams("$prepage");
  }
  else
  {
    $html_text = "<h3>error: no session action</h3>";
  }
  return $html_text;
}

#------------------------------------------------------------------------------
# RenderSessionMenu
# ex: Session::RenderSessionMenu();
# takes: page_name as cgi param
# returns: $html_text
#------------------------------------------------------------------------------
sub RenderSessionMenu
{
  my $page_name = sparam("page")?sparam("page"):"Home";
  my $html_text ="<div class='smenu'>";
  my $skin_dir = $LocalSettings::SkinDir;

  if(defined($page_name = Util::ValidateAndFixupPageName($page_name)))
  {
     if(defined(my $user = InSession()))
     {
       if(($page_name =~ m/$LocalSettings::WikiOldPagesDirName\//))
       {
         $html_text .= "You are viewing an old version of a page. Click your browsers BACK button to return.";
         $html_text .= "<a class='smenu' href='View.cgi?page=$page_name&action=source'>Source</a>\n";
       }
       else
       {
          
          $html_text .= "<a class='smenu' href='View.cgi?page=$page_name'>Article</a>\n";
          # if user has rights to SYSOP group OR the page does not have restricted edit sections then show the edit page link.
          if((Util::OpenFile2String($page_name) !~ /<!--BEGINEDITSECTION-->/)||(!defined(GroupProtected("<!--GROUP:SYSOP-->"))))
          {
             $html_text .= "<a class='smenu' href='Edit.cgi?page=$page_name&action=edit'>Edit</a>\n";
          }
          $html_text .= "<a class='smenu' href='View.cgi?page=$page_name&action=source'>Source</a>\n";
          $html_text .= "<a class='smenu' href='Find.cgi'>Find</a>\n";
          $html_text .= "<a class='smenu' href='Edit.cgi?page=$page_name&action=history'>History</a>\n";
          $html_text .= "<a class='smenu' href='Upload.cgi'>Upload</a>\n";
          $html_text .= "<a class='smenu' href='Login.cgi?action=logout&prepage=$page_name'>Logout: <i>$user</i><img src='$skin_dir/user.gif'></a>\n";
          $html_text .= "<a class='smenu' href='Login.cgi?action=update&prepage=$page_name'>Account</a>\n";

          # if this user has rights to SYSOP group then add this menu item...
          if(!defined(GroupProtected("<!--GROUP:SYSOP-->")))
          {
            # SYSOPs can create accounts even if the general public can not.
            $html_text .= "<a class='smenu' href='Login.cgi?action=new&prepage=$page_name'>Create Account</a>\n";
          }
       }
     }
     else
     {
       if($LocalSettings::HideSessionMenu eq "true") # make it NOT look like a wiki.
       {
         $html_text .= "<a class='smenu' href='Find.cgi'>Find</a>\n";
         $html_text .= "<a class='smenu' href='Login.cgi?action=login&prepage=$page_name'><img src='$skin_dir/user.gif'></a>\n";
       }
       else # show full logged out wiki menu.
       {
         $html_text .= "<a class='smenu' href='View.cgi?page=$page_name'>Article</a>\n";
         $html_text .= "<a class='smenu' href='View.cgi?page=$page_name&action=source'>Source</a>\n";
         $html_text .= "<a class='smenu' href='Find.cgi'>Find</a>\n";
         $html_text .= "<a class='smenu' href='Login.cgi?action=login&prepage=$page_name'>Login</a>\n";
       }
     }
  }

  $html_text .= "</div><p>";
  return $html_text;
}

#------------------------------------------------------------------------------
# AuthenticateCgiParams - this function works in two different modes:
# ex: AuthenticateCgiParams($previous_page);
# takes: $prepage - previous page.
# returns: $html_text that informs user if they have been logged in or not.
#------------------------------------------------------------------------------
sub AuthenticateCgiParams
{
  my $prepage = shift;
  my @account_record;
  my $html_text;
  my $username;
  my $password;
  my $cryptedpw;

  if(!defined(sparam("username")) || !defined(sparam("password")))
  {
     $html_text = "<b>Missing login field: Try <a href='Login.cgi?prepage=$prepage'>again</a>.</b>";
     return $html_text;
  }
  $username = sparam("username");
  $password = sparam("password");  # not crypted from login form.
  $cryptedpw = crypt($password,$username);


  if( (@account_record=FindUser($username)) && ($account_record[1] eq $cryptedpw) ) # AUTHENTICATED = TRUE
  {
     $html_text = SetCookie($UserCookie,$username,$CookieHours);
     $html_text .= SetCookie($CryptedPWCookie,$cryptedpw,$CookieHours);
     $html_text .= "<p><b>You are now logged in.</b> <!--$cryptedpw--><p> Return to <a href='View.cgi?page=$prepage'>$prepage</a>.<script language='javascript'>document.location='View.cgi?page=$prepage'</script>";
  }
  else # AUTHENTICATED = FALSE
  {
     $html_text = "<b>Login invalid: Try <a href='Login.cgi?action=login&prepage=$prepage'>again</a>.</b>";
  }

  return $html_text;
}

#------------------------------------------------------------------------------
# InSession
# ex: if(Session::InSession()) {...}
# takes: nothing
# returns: $username if authenticated, undef if not authenticated.
#------------------------------------------------------------------------------
sub InSession
{
  my @account_record;
  my $username;
  my $cryptedpw;
  my $result;

  $username = GetCookie("$UserCookie");
  $cryptedpw = GetCookie("$CryptedPWCookie"); # crypted from cookied.

  if( (@account_record=FindUser($username)) && ($account_record[1] eq $cryptedpw) ) # AUTHENTICATED = TRUE
  {
     $result =  "$username";
  }
  else # AUTHENTICATED = FALSE
  {
     $result = undef;
  }
  return $result;
}
#------------------------------------------------------------------------------
# RenderLogin
# ex: $html_text = RenderLogin($prepage);
# takes: previous page - in order to redirect user back after submitting form.
# returns: html text string containing html form code to write to client.
#------------------------------------------------------------------------------
sub RenderLogin
{
  my $prepage = shift;
  my $form = <<HTMLEND;
  <p>Login or
  <a href="$LoginTemplate?action=new&prepage=$prepage">Create New Account</a><p>
  <form name="form1" method="post" action="$LoginTemplate">
  <input type="hidden" name="prepage" value="$prepage">
  <input type="hidden" name="action" value="authenticate">
  <table border=0>
  <tr><td>Username:</td><td><input type="text" name="username"></td></tr>
  <tr><td>Password:</td><td> <input type="password" name="password"></td></tr>
  <tr><td></td><td><input type="submit" value="Submit"></td></tr>
  <table>
  </form>
  <script language="javascript">document.form1.username.focus();</script>
  <p><a href="$LoginTemplate?action=forgotpw&prepage=$prepage">Forgot password?</a>
  <p><b>IMPORTANT NOTE:</b> After you submit, if you still see the [login] at the top of the page (as if you're not logged in), click your browser's refresh button.
HTMLEND
  return $form;
}
#------------------------------------------------------------------------------
# RenderPasswordReset
# ex: $html_text = RenderPasswordReset($prepage);
# takes: previous page - in order to redirect user back after submitting form.
# returns: html text string containing html form code to write to client.
#------------------------------------------------------------------------------
sub RenderPasswordReset
{
  my $prepage = shift;
  my $form = <<HTMLEND;
  <p>Password Reset: Enter your username and a new password will be sent to you.
  <form name="form1" method="post" action="$LoginTemplate">
  <input type="hidden" name="prepage" value="$prepage">
  <input type="hidden" name="action" value="mailpw">
  <table border=0>
  <tr><td>Username:</td><td><input type="text" name="username"></td></tr>
  <tr><td></td><td><input type="submit" value="Submit"></td></tr>
  <table>
  </form>
  <script language="javascript">document.form1.email.focus();</script>
HTMLEND
  return $form;
}
#------------------------------------------------------------------------------
# RenderAccountForm
# ex: $html_text = RenderAccountForm("new",$prepage);
# takes: mode - new|undate
# takes: previous page - in order to redirect user back after submitting form.
# returns: html text string containing html form code to write to client.
#------------------------------------------------------------------------------
sub RenderAccountForm
{
  my $mode = shift;
  my $prepage = shift;
  my $cryptedpw;
  my $username;
  my $form="";
  my $line;
  my @array;
  my $authenticated = "false";
  my $readonly = "";

  if($mode eq "new")
  {
    $form = "<p>New Account<p>";
  }
  else # mode = update
  {
    $readonly = "readonly";
    $form = "<p>Update Account<p>";
    $cryptedpw = GetCookie("$CryptedPWCookie");
    $username = GetCookie("$UserCookie");
    if(defined($cryptedpw) && defined($username))
    {
      if(@array = FindUser($username))
      {
        if($array[1] eq $cryptedpw) { $authenticated = "true"; }
      }
    }
    if($authenticated eq "false")
    {
      return "<p><b>Account not found</b>";
    }
  }
  my $action = $mode."account";
  $form .= <<HTMLEND;
  <form name="form1" method="post" action="$LoginTemplate">
  <input type="hidden" name="prepage" value="$prepage">
  <input type="hidden" name="action" value="$action">
  <table border=0>
  <tr><td>Username:</td><td><input $readonly type="text" name="username" value="$array[0]"></td></tr>
  <tr><td>Password:</td><td> <input type="password" name="password" value="$array[1]"></td></tr>
  <tr><td>Email:</td><td> <input type="text" name="email" value="$array[2]"></td></tr>
  <tr><td>
      </td><td>
        <input type="button" value="Submit" onclick="javascript:if(CheckForm(this.form)) this.form.submit();" >
        <a href="javascript:document.location='View.cgi?page=$prepage';">Cancel</a>
      </td></tr>
  <table>
</form>
HTMLEND
  return $form;
}
#------------------------------------------------------------------------------
# GetCookie
# ex: $username = GetCookie("$UserCookie");
# takes: cookiename
# returns value of cookie or empty string if it can't find it.
#   This routine does not use javascript - it reads cookies from the
#   HTTP_COOKIE environment variable.
#------------------------------------------------------------------------------
sub GetCookie
{
  my $name = shift;
  my $value="";
  my $all_cookies = $ENV{'HTTP_COOKIE'};
  if(defined($all_cookies))
  {
    my @cookies = split(/;/,$all_cookies);
    foreach (@cookies){
      if(/\s*$name=/) {
        ($value = $_) =~ s/\s*$name=(.*?)/$1/;
      }
    }
  }
  return $value;
}
#------------------------------------------------------------------------------
# DeleteCookie
# ex: $html_text = DeleteCookie("$UserCookie");
# takes: cookiename.
# returns: html text string containing JAVASCRIPT cookie code to write to the client.
#------------------------------------------------------------------------------
sub DeleteCookie
{
  my $name = shift;
  my $html = <<END_OF_TEXT;
      <script language="javascript"> /* DeleteCookie() */
      var expdate = new Date();
      expdate.setTime (expdate.getTime()+(60*60*1000)); /* Now */
      document.cookie = "$name=; expires=" +expdate.toGMTString()+";";
      </script>
END_OF_TEXT
  return $html;
}
#------------------------------------------------------------------------------
# SetCookie
# ex: $html_text = SetCookie($UserCookie,$username,$CookieHours);
# takes: cookiename, valueOfcookie and hours expiration time
# returns: html text string containing JAVASCRIPT cookie code to write to the client.
#------------------------------------------------------------------------------
sub SetCookie
{
  my $name = shift;
  my $value = shift;
  my $hours = shift;
  my $html_text = <<END_OF_TEXT;
      <script language="javascript">  /* SetCookie() */
      var expdate = new Date();
      expdate.setTime (expdate.getTime()+(60*60*1000*$hours));
      document.cookie = "$name=" +escape("$value")+ "; expires=" +expdate.toGMTString()+";";
      </script>
END_OF_TEXT
  return $html_text;
}
#------------------------------------------------------------------------------
# FindUser - finds username in the Users.wiki
#  Account information has the following format:
#  *username:OIkJOlsko:user@domain.com
# ex: if(@array = FindUser(sparam("username"))) {...}
# takes: username
# returns: array with all account info for the user.
# returns: array of zero length if no user found.
#------------------------------------------------------------------------------
sub FindUser
{
  my $username = shift;
  my $line;
  my @array;
  my $found = "false";
  if(open(INFILE,'<',"$PWFile"))
  {
    binmode INFILE;
    while (defined($line = <INFILE>))  # gets one line at a time.
    {
      @array=split(/$DELIM/,$line);  # parse file line into components.
      $array[0] =~ s/\*//;  # remove bullet at front
      if($array[0] =~ m/$username/)
      {
        $found = "true";
        last;
      }
    }
    close(INFILE);
  }
  if($found eq "false") { @array=(); } # clear last entry.
  return @array;
}
#------------------------------------------------------------------------------
# SaveUserProfile
# ex: if(defined(SaveUserProfile("update",@array))) {...}
# takes: mode - new(appends data) |update (replaces data)
# returns: undef if unsuccessful
# returns: true if success.
#------------------------------------------------------------------------------
sub SaveUserProfile
{
  my ($mode,@array) = @_;
  my $newline = join("$DELIM",@array);
  $newline = "*" . $newline;  # put bullet on front.
  chomp($newline);
  my $line;
  my $all_lines = "";
  if(open(INFILE,'<',"$PWFile"))
  {
    binmode INFILE;
    while (defined($line = <INFILE>))  # gets one line at a time.
    {
      $all_lines .= $line;
    }
    close(INFILE);
  }
  else
  {
    return undef;
  }
  if($mode eq "update")
  {
    # match the username. don't care about the rest.
    $all_lines =~ s/^\*$array[0]:(.*)/"$newline"/emg;
  }
  else # mode = new
  {
    $all_lines .= "\n".$newline;
  }
  if(open(OUTFILE,'>',"$PWFile"))
  {
    binmode OUTFILE;
    print OUTFILE $all_lines;
    close(OUTFILE);
  }
  else
  {
    return undef;
  }
  return "true";
}
#------------------------------------------------------------------------------
# GroupProtected
#  checks to see if user has permission rights as specified by the group tag
#  and the Special:Groups file list.
# ex. if(defined($deny_message = Session::GroupProtected($wiki_text))) {...}
# takes: wiki_text, one file is one string
# returns: undefined if not protected or user has rights.
# returns: error message if user can not access.
#------------------------------------------------------------------------------
sub GroupProtected
{
  my $wiki_text = shift;
  my $line;
  my $has_permission= "false";
  my $group;
  my $username = GetCookie("$UserCookie");

  # if cookie does not exist at all.
  if(!defined($username)) {  return "GroupProtected:username undefined"; }

  # When a user is logged out there is an empty cookie
  # still there. It as nothing but whitespace for a value. So here we
  # check for that condition.
  if($username =~/^\s*?$/) {  return "GroupProtected:username undefined"; }

  my @groups = ();
  my @wikilines = split(/\n/,$wiki_text);
  foreach $line (@wikilines)
  {
     if($line=~/<!--GROUP/) # if the GROUP tag is in the wiki text.
     {
       $group = $line;
       $group =~ s/.*?<!--GROUP:(.*?)-->.*/$1/;
       push @groups, $group;  # Push each found GROUP tag group into this array.
     }
  }
  undef $line;
  if(@groups) # if there are groups with in this array.
  {
    if(open(INFILE,'<',"$GroupsFile"))
    {
      binmode INFILE;
      while (defined($line = <INFILE>))
      {
        foreach $group (@groups)
        {
          if($line=~/^\*\s*$group:/)
          {
            if($line=~/$username/)  # if found (delimiter doesn't matter just that its on same line).
            {
              $has_permission = "true";
              last;
            }
          }
        }
      }
      close(INFILE);
    }
    else
    {
      return "GroupProtected:Could not open Groups File.";
    }
  }
  else # There are no permission restrictions for this page.
  {
    $has_permission = "true";
  }

  if($has_permission eq "true")
  {
     return undef;
  }
  else
  {
    $line = "Page is Group restricted to:";
    foreach $group (@groups) {  $line .= " $group "; }
    return $line;
  }
}
#------------------------------------------------------------------------------
# ViewProtected
#   Wiki pages can include a <!--PRIVATE--> tag within the text ALONG with
#   one or more GROUP tags <!--GROUP:Alchemists--> to restrict public viewing.
#   If user doesn't specify a group then its still viewable (because otherwise
#   the user and everyone else would be locked out!!).
# ex. if(defined($deny_message = Session::ViewProtected($wiki_text))) {...}
# takes: wiki_text, one file is one string
# returns: undefined if user has rights to view (by being in specified group) or
#  there is no <!--PRIVATE--> tag within wiki page
# returns: error message if user can not view.
#------------------------------------------------------------------------------
sub ViewProtected
{
   my $wiki_text = shift;
   if($wiki_text =~ m/<!--PRIVATE-->/sg)
   {
      if($wiki_text =~ m/<!--GROUP/sg)
      {
         if(defined(GroupProtected($wiki_text)))
         {
           return "This page is private from public viewing.";
         }
      }
   }
   return undef;
}
#------------------------------------------------------------------------------
# NamespaceProtected
#  checks to see if user has permission rights as specified by
#  the Special:Namespaces file list.
#  The Namespaces file contains users per namespace and ONLY those users can
#  edit pages within the namespace. This tactic is opposite of group permissions
#  and tags which work on individual pages.
# ex. if(defined($deny_message = Session::NamespaceProtectedProtected($page_name))) {...}
# takes: page_name, obvious this will contain the namespace i.e. Namespace/Pagename
# returns: undefined if not protected or user has rights.
# returns: error message if user can not access.
#------------------------------------------------------------------------------
sub NamespaceProtected
{
  my $page_name = shift;
  my $line;
  my $has_permission= "false";
  my $found_namespace ="false";
  my $namespace;
  my $username = GetCookie("$UserCookie");

  if($page_name =~ /[\/|:]/)
  {
    ($namespace = $page_name) =~ s/(.*?)[\/|:].*/$1/g; #extract namespace
  }
  else
  {
    $namespace = "Main";
  }

  #print ">>$namespace<<>>$page_name<<";

  # if cookie does not exist at all.
  if(!defined($username)) {  return "NamespaceProtected:username undefined"; }

  # When a user is logged out there is an empty cookie
  # still there. It as nothing but whitespace for a value. So here we
  # check for that condition.
  if($username =~/^\s*?$/) {  return "NamespaceProtected:username undefined"; }

  if(open(INFILE,'<',"$NamespacesFile"))
  {
    binmode INFILE;

    while (defined($line = <INFILE>))
    {
      if($line=~/^\*\s*$namespace:/) # if this namespace is in the NamespacesFile.
      {
        $found_namespace = "true";
        if($line=~/$username/)  # if found (delimiter doesn't matter just that its on same line).
        {
          $has_permission= "true";
        }
      }
    }
    close(INFILE);
  }
  else
  {
    return "NamespaceProtected:Could not open NamespacesFile.";
  }

  if(($has_permission eq "true")||($found_namespace eq "false"))
  {
     return undef;
  }
  else
  {
    $line = "User $username does not have permissions to edit pages in namespace: $namespace";
    return $line;
  }
}
#------------------------------------------------------------------------------
# History:
# * Added code for using <!--BEGINEDITSECTION--> and <!--ENDEDITSECTION--> tags.
# * Added password reset
# * Added password reset email activation instead of default password reset.
#------------------------------------------------------------------------------
1;
