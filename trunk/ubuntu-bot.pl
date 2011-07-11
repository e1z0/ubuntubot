#!/usr/bin/perl -w

# UbuntuBot
# Copyright (c) 2009-2011 \dev\null. Licensed under GPLv3 License.

# Ubuntu Bot Startup file

use strict;
use lib "/home/devnull/ubuntu-bot/botas";
use Botas;

my $bot = Ubuntubot->new("/home/devnull/ubuntu-bot/botas/startup_and_cfg/ubuntu-bot.cfg");

$bot->init;
$bot->daemonize;
$bot->start_session;
