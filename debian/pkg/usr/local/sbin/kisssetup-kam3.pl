#!/usr/bin/perl 

# $Id: kisssetup.pl,v 8.0 2011/07/01 21:52:23 n7nmd Exp $
# Copyright (C) 2011  Dan Zubey, N7NMD
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.
#

# This script connects to a TNC2 modem on /dev/tnc, and carefully sets it up into KISS mode.
# You need to specify port name and, terminal speed. Also ensure that no other (kissattach, xastir, etc) process 
# is using the given port before using this script. We try to kill kissattach.
 
# Requires: Device::SerialPort ... cpan Device::SerialPort as root.
# 

use Device::SerialPort;
system ("killall kissattach");
$tnc=pop(@ARGV);
$speed=pop(@ARGV);

my $port=Device::SerialPort->new($tnc);

$datarate=9600;

$port->databits(8);
$port->baudrate(9600);
$port->parity("none");
$port->stopbits(1);
my $STALL_DEFAULT=0; # how many seconds to wait for new input
my $timeout=$STALL_DEFAULT;
$port->read_char_time(1);     # don't wait for each character
$port->read_const_time(0); # 1 second per unfulfilled "read" call

my $kissoff=sprintf("%c%c%c", 192, 255, 192); # Special kiss-off command
my $notconverse = sprintf("%c%c%c",03,11,03); # special get-out-of-converse-mode command
my $chars=0;
my $buffer="";

@reset_string=(
"\r\r",
"INT TERMINAL",
"RESET",
"ECHO ON",
"VERSION",
"TRFLOW OFF",
"TXFLOW OFF",
"XFLOW OFF",
"AutoLF ON",
"HBAUD 1200",
"INT KISS",
"CD SOFTWARE",
"ECHO ON",
"MALL ON",
"FLow off",
"MCOM off",
"MON ON",
"INT KISS",
"RESET");

#"MAX 1",
#"P 254",
#"TRACE on",

sub senddata ()
{
my ($stringout) = @_;

    my $writeresponse = $port->write($stringout . "\r");
    $response = $port->read(254);
    print $response;
}

#Turn kiss off.
&senddata ($kissoff);

#  This ensures we are NOT in command converse mode.
&senddata ($notconverse);

&senddata ("INT TERMINAL");
&senddata ("RESET");

#Zip through all the commands and send one at a time.
foreach $reset_string (@reset_string){
    &senddata ($reset_string);    
}
