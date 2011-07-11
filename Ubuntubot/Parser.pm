package Ubuntubot::Parser;

# UbuntuBot
# Copyright (c) 2009-2011 \dev\null. Licensed under GPLv3 License.


use strict;
use warnings;


sub parse
{

	# first pass
	# determine whether the line is a privmsg, or a system
	# message, and deal with accordingly

	# this method is called every time the bot sees a line of text/data
	# so make it clean and efficient
	
	my ($self, $line) = @_;

	# get rid of \r at end and/or get rid of newlines if they are there
	
  $line =~ tr/\r\n//d;
  
  $self->set(LINE => $line);
	
	# are we dealing with a privmsg (channel message or msg from user) ?
	# if so, call priv msg handling routine
	# if not, send to routine that handles non-chat

	if ($line =~ /^:\S+\s+PRIVMSG\s+/)
	{
		
		_msg_handler($self, $line);

	}
	else
	{

		_sys_handler($self, $line);

	}

	# this would be a good place to log data
	
	
}


sub _sys_handler
{

	# handle non-chat like server to client ping, etc.

	(my $self, local $_) = @_;

	# remove character that lets people do ACTIONs and the like
	tr/\001//d;

	my $nick = $self->bot_cfg("NICK");

	# Messages that can be ignored
	# this is incomplete but better than nothing - I am too lazy to figure out all codes
	return if /^:\S+\s+(?:37[256]|25[1235]|353|366|00[234]|NOTICE) /i;
  
	# Server to client ping
	return $self->act( PONG => $1 ) if /^ping :(\S+)/i;

	# restart bot if an error occurs
	$self->restart_bot("IRCD ERROR: $1") if /^ERROR :(.+?)\s*$/i;
	
		
	# Nick is already in use
	if (/^:\S+ 433 /)
	{

		# change Ubuntubot to tUbuntuBot, tUbuntuBot to otUbuntuBot, etc.
		# isn't completely fool-proof but should do the job
		$nick =~ s/(.+)(.)$/$2$1/;
		return $self->act( SET_NICK => $nick );

	}
  
  # needs to callback to the some function using global variables
  $self->get_who("$_") if /^:\S+\s+352\s+/;
  # callback
  $self->get_chans("$_") if /^:\S+\s+319\s+/;
  # Automatically rejoin if kicked
	return $self->act( JOIN_CHAN => $1 ) if /^:\S+ KICK (\S+) $nick :/i and lc $self->bot_cfg("AUTO_REJOIN") eq "yes";
	# Automatically ban/kick user on join
	# ("channel, nick, $host")
	$self->check_banned($3, $1, $2) if /:(.*)!.*@(.*) JOIN :(.*)/i and lc $self->bot_cfg("BAN_MECHANISM") eq "yes";
	# check user against bad channels
	$self->chans_action($3, $1, "badcheck") if /:(.*)!.*@(.*) JOIN :(.*)/i and lc $self->bot_cfg("BAN_MECHANISM") eq "yes";
	# voice bot moderators ( channel, nick, hostmask )
	$self->voice_user($3, $1, $2) if /:(.*)!.*@(.*) JOIN :(.*)/i;
	# for debug reasons
	#$self->log_msg("Atejo i kanala $3 nickas $1 hostas $2") if /:(.*)!.*@(.*) JOIN :(.*)/i and lc $self->bot_cfg("BAN_MECHANISM") eq "yes";
}


sub _msg_handler
{

	(my($self), local($_)) = @_;

	# ignore "actions"
	# need bugfix
	#return if tr/\001//d;
	
	# respond to CTCP queries
	
	# CTCP Ping
	return $self->act( CTCP_PING => $1, $2 )
	    if /^:([^!]+)!\S+ PRIVMSG [#&]?\S+ :\x01PING\s*(.*?)\s*\x01$/i;
	
	# CTCP Version
	return $self->act( CTCP_VERSION => $1 )
		if /^:([^!]+)!\S+ PRIVMSG [#&]?\S+ :\x01VERSION\s?\x01$/i;

	# CTCP Time
	return $self->act( CTCP_TIME => $1 )
		if /^:([^!]+)!\S+ PRIVMSG [#&]?\S+ :\x01TIME\s?\x01$/i;
	
	# now that CTCP's are done, remove character that lets people do ACTIONs and the like
	tr/\001//d;

	# set configuration data for this line of input
	# i.e. who talked to the bot, the channel, etc.

	# are we being spoken to in a channel, or via priv chat?

	my $my_nick			= $self->bot_cfg("NICK");

	my $WHISPERED_TO	= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG [^#& ]+ :\s*(.+?)\s*([.?!]*)\s*$/;
	my $SPOKEN_TO_1		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*$my_nick(?:[,:]|\s+)\s*(.*?)\s*([.?!]*)\s*$/i;	# "$nick, hello" spoken directly to
	my $SPOKEN_TO_2		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*(.+?)\s*,?\s*$my_nick\s*([.?!]*)\s*$/i;	# "hello $nick"  - indirect
	my $NOT_SPOKEN_TO	= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*(.+?)([.?!]*)?\s*$/;

	# set processed lines
  #my $processed = $self->get("processed_lines")+1;
  $self->set(processed_lines => $self->get("processed_lines")+1); 
  
	
	# was the bot spoken to in a private message (from user to bot PRIVMSG)?
	if ( /$WHISPERED_TO/ )
	{

		$self->set(user_nick => $1, user_name => $2, user_mask => $3, chan => $1, query => $4, punctuation => ($5 || ""), whisper => 1);
		
		# ignore user?
		return if $self->ignore_user_check($1);
    $self->spoken_to;
		
	}
	# the bot was spoken to while in a channel (i.e. <user> Ubuntubot: Hi!)
	elsif ( /$SPOKEN_TO_1/ || /$SPOKEN_TO_2/ )
	{
        
		$self->set(user_nick => $1, user_name => $2, user_mask => $3, chan => $4, query => $5, punctuation => ($6 || ""), whisper => 0);
		
		# ignore user?
		return if $self->ignore_user_check($1);

		# ignore whole channel?
		return if $self->ignore_channel_check($4);

		$self->spoken_to;
		
	}
	# not spoken to	in a channel
	elsif ( /$NOT_SPOKEN_TO/ )
	{

		$self->set(user_nick => $1, user_name => $2, user_mask => $3, chan => $4, query => $5, punctuation => ($6 || ""), whisper => 0);

		# it's a query if we're on a LISTEN_ON channel
		if ($self->contains($4, [split /\s+/, $self->bot_cfg("LISTEN_ON")||""]))
		{

			# ignore user?
			return if $self->ignore_user_check($1);

			# do karma check
			$self->karma_check;

			# look for URIs to be saved
			$self->uri_in_msg_check($5, $4);
			# hack to save all urls (channel, nick, text)
			# $self->log_msg("testas $4 $1");
			
      #$self->save_all_urls($4, $1, $5);

			$self->spoken_to;

		}
		# just chat otherwise (not being spoken to)
		else
		{

			# ignore user?
			return if $self->ignore_user_check($1);

			# do karma check
			$self->karma_check;

			# hack to save all urls (channel, nick, text)
			#$self->log_msg("testas $4 $1 $5");
			$self->save_all_urls($4, $1, $5);
			# baninimas (BAN_MECHANISM = yes)
			# ("channel, nick, $host")
	    $self->check_banned($4, $1, $3) if $self->bot_cfg("BAN_MECHANISM") eq "yes";
	    $self->check_spam($4, $1, $3, $5) if $self->bot_cfg("CHECK_SPAM") eq "yes";
	    			
			
      # look for URIs to be saved
			
			$self->uri_in_msg_check($5, $4);

			$self->not_spoken_to;

		}
			
	}

}

1;
