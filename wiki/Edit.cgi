#!/usr/bin/perl -w
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
use strict;
use LocalSettings;
use Wiki2Html;
use Editor;
use Session;

my $buffer;
my $template = "$LocalSettings::SkinDir/Template.tmpl";

{ # local block: Load template into buffer.
local $/ = undef;
open(FILE,'<',"$template") || die "couldn't open $template for reading: $!\n";
$buffer = <FILE>;
close(FILE);
}

print "Content-Type:text/html\n\n";

# Expand the following TAGs within the template.
$buffer =~ s/<!--TITLE-->/$LocalSettings::WikiSiteTitle/;
$buffer =~ s/<!--STYLE-->/$LocalSettings::SkinDir\/main.css/;
$buffer =~ s/<!--COMMONJS-->/$LocalSettings::CommonJsDir\/Common.js/;
$buffer =~ s/<!--LOGO1-->/$LocalSettings::SkinDir\/logo1.png/;
$buffer =~ s/<!--LOGO2-->/$LocalSettings::SkinDir\/logo2.gif/;
$buffer =~ s/<!--SIDEBAR-->/Wiki2Html::WikiRender("$LocalSettings::SidebarPageName")/e;
$buffer =~ s/<!--SESSIONMENUBAR-->/Session::RenderSessionMenu()/e;
$buffer =~ s/<!--CONTENT-->/Editor::WikiEdit()/e;

print "$buffer"; # print the html to the client browser.
#---------------------------------------------------------------------------------------
