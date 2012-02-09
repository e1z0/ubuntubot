package Ubuntubot::Pipeline;

# UbuntuBot
# Copyright (c) 2009-2012 \dev\null. Licensed under GPLv3 License.

use strict;
use warnings;
use URI::Escape;
use List::Util;

sub spoken_to {
	my ($self)	= @_;
	local $_	= $self->get("query");
	my ($who, $chan, $whisper) = $self->get(qw/user_nick chan whisper/);
	
	# study $_
	study;
	
	# set question stats
	$self->set(processed_questions => $self->get("processed_questions") + 1);
	
	# say hi
	if ( /^(hi|hello|hey|yo|sup|labas|sveikas)\s*$/i ) {
		$self->act( SAY => $chan, "$1 $who" . $self->get("punctuation") );
	}
	elsif (/^(bananas|ban|kickban|kb|baninti|banink|mesk|ismesk|ismesti|uzbaninti|baninti|banint|nubausti|nubausk|bausti)\s+(\S+)\s+(.+?)\s*$/i ) {
        $self->act( SAY => $chan, "fail" ), return if ($2 =~ /\*/);

        $self->act( SAY => $chan, "Eik tu, batsiuvy! ;-)" ), return
	        unless $self->user_access( CHECK_MASK => $who) and $self->user_access( GET_USER_DATA => $who, "level" ) >= 3;
	
	    $self->act( SAY => $chan, "Na čia dabar, dar mane sugalvosi bananais pavaišint? :'("), return
	        unless ($2 ne $self->bot_cfg("NICK"));
	
	    $self->act( SAY => $chan, "Bijau taip padaryt, nes paskui galiu gaut velnių :|"), return
	        unless ($self->user_access( GET_USER_DATA => $who, "level" ) >= $self->user_access( GET_USER_DATA => $2, "level" )); 
    
        $self->add_banana($2, $who, $chan, $3 );
    }
    # blacklist user
    elsif (/^(blacklist|shitlist|banlist|silentban)\s*.*/i) {
        $self->act( SAY => $chan, "Eik tu, batsiuvy! ;-)" ), return
	        unless $self->user_access( CHECK_MASK => $who) and $self->user_access( GET_USER_DATA => $who, "level" ) >= 3;
	
	    $self->act( SAY => $chan, "Na čia dabar, dar mane sugalvosi bananais pavaišint? :'("), return
	        unless ($2 ne $self->bot_cfg("NICK"));
	
	    $self->act( SAY => $chan, "Bijau taip padaryt :|"), return
	        unless ($self->user_access( GET_USER_DATA => $who, "level" ) >= $self->user_access( GET_USER_DATA => $2, "level" )); 
    
        if (/^(blacklist|silentban|shitlist|banlist)\s+(.+?) (.+?) (.+?)\s*$/i) {
            #$self->act( SAY => $chan, "ok nickas $2 hostas $3 reasonas $4" );
            $self->silent_banana($2, $3, $4, $who, $chan);
        }
        else {
            $self->act( SAY => $chan, "Nurodyk nick'ą host'ą ir priežastį." );
        }
    }
    elsif (/^(atbaninti|nuimti bana|atbanink|unban)\s+(.+?)\s*$/i) {
        $self->act( SAY => $chan, "Eik tu, batsiuvy! ;-)" ), return
	        unless $self->user_access( CHECK_MASK => $who) and $self->user_access( GET_USER_DATA => $who, "level" ) >= 3;
	
        $self->del_banana($2, $chan);
    }
    elsif (/^(check|tikrink)\s+(.+?)\s*$/i) {
        $self->act( SAY => $chan, ":-(" ), return
	        unless $self->user_access( GET_USER_DATA => $who, "level" ) >= 1;
  
        $self->chans_action($chan, $2, "badcheck");
    }
    elsif (/^(host|hostas)\s+(.+?)\s*$/i ) {
        # gets user's host and prints to the channel
        $self->act( SAY => $chan, "Eik tu, batsiuvy! ;-)" ), return
	        unless $self->user_access( CHECK_MASK => $who) and $self->user_access( GET_USER_DATA => $who, "level" ) >= 1;
	  
        $self->who_action($chan, $2, "printwho");
    }
    # sakyk <nickui> apie <tekstas>
	elsif ( /^(?:sakyk|pasakyk|mestelk)\s+(\S+)\s+(?:apie|to)\s+(.+?)\s*$/i ) {
		$self->tell( $1, $who, $chan, $2 );
	}
	
	# bot <topic> > <user>
	elsif ( /^(.+?)\s*>\s*(\S+)\s*$/i )	{
		$self->tell( $2, $who, $chan, $1 );
	}
	
	# matematinės funkcijos (in Ubuntubot::Common)
	elsif ( /^(?:math|calc|skaiciuot|skaiciuoti)\s+(.+?)\s*$/i ) {
		$self->act( SAY => $chan, $self->math($1) );
	}
	# GeoIP (in Ubuntubot::Common)
	elsif ( /^geo\s*ip\s+(\S+)\s*$/i ) {
		$self->act( SAY => $chan, $self->geoip($1) );
	}
	
	# shorten last uri seen in channel
	# need bugfix this feature
	# sutrumpintas
	# trumpint paskutine 
	# sutrumpina paskutine kanale rodyta nuoroda
	elsif ( /^trumpint\s+(?:it|(?:paskutine(?:\s+ur[il])?))\s*$/i )	{
  		if (my $url = $self->chan_url( GET => $chan )) {
  			$self->act( SAY => $chan, "Sutrumpintas: " . $self->shorten_url($url) );
  		}
		else {
			$self->act( SAY => $chan, "$who, aš dar nemačiau jokios nuorodos kanale $chan" );
		}
	}
	# shorten a url
	# sutrumpint
	elsif ( /^sutrumpint\s+(.+?)\s*$/i ) {
  		$self->act( SAY => $chan, "Sutrumpinta nuoroda: " . $self->shorten_url($1) );
  	}
  	
	# fortune (in Ubuntubot::Common)
	elsif ( /^fortune\s*$/i ) {
		$self->act( SAY => $chan, $self->fortune );
	}
	
	# google
	# need fuckin fix ...
	#elsif ( /^google\s+for\s+(.+?)\s*$/i ) {
	#	$self->act( SAY => $chan, "oblio: google for $1" );
	#}
	
	# parodys sistemos uptime (*nix way) (in Ubuntubot::Common)
    elsif ( /^uptime\s*$/i ) {
        $self->act( SAY => $chan, $self->uptimeas );
    }
    # versija (in Ubuntubot::Common)
    elsif ( /^(version|versija)\s*$/i ) {
        $self->act( SAY => $chan, $self->version );
    }
    # (in Ubuntubot::Common)
    elsif ( /^(statusas|statsai|stats|info)\s*$/i ) {
        $self->act( SAY => $chan, $self->statsai );
    }
    
    #------------------------------
    # what's the difference? - ark
    
    # act stupid
	# buk <nickas>
	elsif ( /^buk\s+(?:a\s+)?retard(?:ed|o)?\s*$/i ) {
        $self->act( SAY => $chan, "Eik tu, batsiuvy! ;-)" ), return
	        unless $self->user_access( CHECK_MASK => $who) and $self->user_access( GET_USER_DATA => $who, "level" ) >= 1;

		$self->act( SAY => $chan, $self->retard );
	}
	# act like someone stupid
	# act|be like <nick>
	# buk|pasirodyk kaip <nickas>
	elsif ( /^(?:buk|pasirodyk)\s+(?:kaip\s+)?(.+?)\s*$/i )	{
		my $be_who = $1;

        $self->act( SAY => $chan, "Eik tu, batsiuvy! ;-)" ), return
	        unless $self->user_access( CHECK_MASK => $who) and $self->user_access( GET_USER_DATA => $who, "level" ) >= 3;
			
		# jei pamini mano nicka kad spirtu i tarpukoji ;-)
		if (lc $be_who eq "\\dev\\null") {
			$self->act( ACTION => $chan, "spiria į $who tarpukojį" );
		}
		else {
			$self->act( SAY => $chan, $self->retard($be_who) );
		}
	}
	#------------------------------
	
	# get karma for something
	# karma|taskai nickui|nikui <nick>
	elsif ( /^(?:karma|taskai)(?:\s+(?:nikui|nickui))?\s+(.+?)\s*$/i ) {
	    # FIXME
        return;
		my $karma_val = $self->karma( GET => $1 );

		my $karma_msg = $karma_val
			? "Karma $1: $karma_val"
			: "$1 neturi jokio karma";
		
		$self->act( SAY => $chan, $karma_msg );
	}
	# top N karma entries
	# top|topas karmos
	# top 20 karmos
	elsif ( /^(?:top|topas)\s+(?:(\d+)\s+)?karmos?\s*$/i ) {
	    # FIXME
        return;
    
		my $num = $1 || 5;
		
		# limit to 20 entries max
		if ($num > 20) {
			$self->act( SAY => $chan, "Atsiprašau, $num yra per didelis rezultatas. Pasirink mažesnį negu 21 numerį" );
		}
		else {
			my $results = join ", ", $self->karma( TOP_N => $num );

			$self->act( SAY => $chan, "Top $num karmų įrašai: $results" );
		}
	}
	# bottom N karma entries
	# paskutiniai|maziausi karmos ?
	elsif ( /^(?:paskutiniai|maziausi|maziausias)\s+(?:(\d+)\s+)?karmos?\s*$/i ) {
        #FIXME
        return;
		my $num = $1 || 5;
		
		# limit to 20 entries max
		if ($num > 20) {
			$self->act( SAY => $chan, "Atsiprašau, $num yra per didelis rezultatas. Pasirink mažesnį negu 21 numerį" );
		}
		else {
			my $results = join ", ", $self->karma( BOTTOM_N => $num );

			$self->act( SAY => $chan, "Paskutiniai $num karma įrašai: $results" );
		}
	}
	# jargon file
	# zargonas skirtas <tekstas>
	elsif ( /^zargonas\s+(?:entry\s+)?(?:skirtas\s+)?(.+?)\s*$/i ) {
        # FIXME
        return;
		my $def = $self->jargon($1);
		$self->act( SAY => $chan, $def );
	}
	
	# pamirsk faktas
	elsif ( /^(pamirsk|pamirsti|uzmirsti|istrinti|pasalinti|salinti)\s+(.+?)\s*$/i ) {
        $self->act( SAY => $chan, "Eik tu, batsiuvy! ;-)" ), return
	        unless $self->user_access( CHECK_MASK => $who) and $self->user_access( GET_USER_DATA => $who, "level" ) >= 2;
	
        my $return = $self->fact( REMOVE => $1 . $self->get("punctuation") );
		$self->act( SAY => $chan, $self->get("FACT_MSG") );
	}
    # perrasyk|owerwrite <faktas> <tekstas>
	# sena eilute elsif ( /^(?:no(?:\s*,)?|overwrite|perrasyti|perrasyk)\s+(.+?)\s+[ia]s\s+(.+?)\s*$/i )
	elsif ( /^(?:no(?:\s*,)?|overwrite|perrasyti|perrasyk)\s+(.+?)\s+(?:yra|kaip)\s+(.+?)\s*$/i ) {
        $self->act( SAY => $chan, "Eik tu, batsiuvy! ;-)" ), return
	        unless $self->user_access( CHECK_MASK => $who) and $self->user_access( GET_USER_DATA => $who, "level" ) >= 2;
	
		# remove fact if it exists
		my $fact_existed = $self->fact( REMOVE => $1);

		# now add the new fact
		my $fact = $2 . $self->get("punctuation");
		my $return = $self->fact( ADD => $1, $fact );
		my $msg = $fact_existed ? "perrašytas $1 įrašas" : "nebuvo jokio $1 įrašo, todėl aš pridėjau naują";
		$self->act( SAY => $chan, $msg );
	}
	# isimink|isiminti <faktas> <tekstas>
	elsif ( /^(?:isimink|irasyk|irasyti|add|prideti|isiminti)\s+(.+?)\s+(?:yra|kaip)\s+(.+?)\s*$/i || /^(.+?)\s+is\s+(.+?)\s*$/i ) {
        $self->act( SAY => $chan, "Eik tu, batsiuvy! ;-)" ), return
	        unless $self->user_access( CHECK_MASK => $who) and $self->user_access( GET_USER_DATA => $who, "level" ) >= 1;
    
		my $fact= $2 . $self->get("punctuation");
		my $return = $self->fact( ADD => $1, $fact );
		my $msg = $return ? $self->get("FACT_MSG") : $self->get("FACT_MSG");
		$self->act( SAY => $chan, $msg );
	}
	# ieskoti
	elsif ( /^(?:fact-?)?ieskoti\s+(?:for\s+)?(.+?)\s*$/i )	{
        return unless $self->user_access( GET_USER_DATA => $who, "level" ) >= 1;
		my @results = map { @$_ } @{ $self->fact( SEARCH => $1 ) };
		
		if (@results) {
			my $msg;
			my $num_res = @results;

			if ($num_res == 1) {
				$msg = "Vienas atitikimas įrašui „$1“: ";
			}
			elsif ($num_res > 25) {
				@results = (List::Util::shuffle(@results))[0..24];
				$msg = "Atsitiktiniai 25 atitikmenys (iš viso jų $num_res) įrašui „$1“: ";
			}
			else {
				$msg = "Rasta $num_res atitikmenų įrašui „$1“: ";
			}
			
			$self->act( SAY => $chan, $msg . join ", ", @results );
		 }
		 else {
			 $self->act( SAY => $chan, "Atsiprašau, bet nei vieno įrašo neaptikau kuris atitinka „$1“" );
		 }
	}
	
	# (username, level, hostmask, password, email)
    # pridetvart
 	elsif ( /^pridetvart\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$/i ) {
        $self->act( SAY => $chan, "Neturi privilegijų !" ), return
	        unless $self->user_access( CHECK_MASK => $who) and $self->user_access( GET_USER_DATA => $who, "level" ) >= 4;
		
		my $msg = $self->user_access( ADD_USER => $1, $2, $3, $4, $5 );
		$self->act( SAY => $chan, $msg );
	}
	# get information about a user that is in the user database
    # vartotojo info \dev\null
	elsif ( /^vartotojo\s*info\s+(\S+)\s*$/i ) {
		my $user = $1;
		
		# get user data
		my %data = $self->user_access( GET_USER_DATA => $user );

		# make sure user exists
		$self->act( SAY => $chan, "Nėra vartotojo $user" ), return unless defined $data{username};

		# user requesting information must be at a higher level than
		# the user who gets the information...
		my $user_level = $data{level};

		# ...except operators and owners can look at all levels
		$user_level = 0
			if  ($self->user_access( CHECK_MASK => $who))
			and ($self->user_access( GET_USER_DATA => $who, "level" ) >= 3);

		my $msg;

		if ($self->user_access( VALIDATE => $who, $user_level))	{
			$msg = "Vartotojas: $data{username}  Priėimo lygis: $data{level}  Hostas: $data{hostmask}  Emailas: $data{email}";
		}
		else {
			$msg = 	"Tu neturi privilegijų!";
		}
		
		$self->act( SAY => $chan, $msg );
	}
	
	# everything else gets compared against the factoid database
	else {
		if (defined( my $fact = $self->fact( GET => $_ ))) {
			# turns %NICK% into $who
			$fact =~ s/\%nick\%/$who/gi;
			
			$self->act( SAY => $chan, $fact )
		}
	}
}

sub not_spoken_to {
	# uncomment code when there is a reason to

	# my $self = shift;

	# local $_    = $self->get("LINE");
	# my $me      = $self->bot_cfg("NICK");
	# my ($who, $chan, $whisper) = $self->get(qw/user_nick chan whisper/);
}

1;
