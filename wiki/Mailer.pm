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
package Mailer;  # force use of fully qualified names
use strict;
use LocalSettings;

#------------------------------------------------------------------------------
# MailMessage
# ex: Mailer::MailMessage();
# takes: to,subject,message
# returns: undef on success, error message on failure.
#------------------------------------------------------------------------------
sub MailMessage
{
  my $to = shift;
  my $subject = shift;
  my $message = shift;
  my $from = $LocalSettings::AdminEmail;
  if($LocalSettings::EnableEmailNotifications eq "true")
  {
    if($LocalSettings::EmailOption eq "sendmail")
    {
      return DoSendMail($to,$from,$subject,$message);
    }
    return "<p><h1>!Error: Invalid LocalSettings value for EmailOption</h1><p>";
  }
  else
  {
    return undef;
  }
}

#------------------------------------------------------------------------------
# DoSendMail
#   This is the subroutine for Unix sendmail implementation.
# takes: to,from,subject,message
# returns: undef on success, error message on failure.
#------------------------------------------------------------------------------
sub DoSendMail
{
  my $to = shift;
  my $from = shift;
  my $subject = shift;
  my $message = shift;
  if (-e $LocalSettings::SendmailAppPath)
  {
    open(SM, "|$LocalSettings::SendmailAppPath -t") or return "<p><h1>!Error: Sendmail failed</h1><p>";
    print SM "to: $to\n";
    print SM "from: $from\n";
    print SM "subject: $subject\n\n";
    print SM "\n\n";
    print SM "$message\n";
    close(SM);
    return undef;
  }
  else
  {
    return "\n<p>$LocalSettings::SendmailAppPath not available. Would have sent:<br>To:$to<br>From: $from<br>Subject:$subject<br>Message:$message<p>\n";
  }
}

###############################################################################
1;
