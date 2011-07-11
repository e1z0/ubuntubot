package Ubuntubot::Common;

# UbuntuBot
# Copyright (c) 2009-2011 \dev\null. Licensed under GPLv3 License.

use strict;
use warnings;

# modules
use Ubuntubot::Util::Host;
use Ubuntubot::Util::Math;
use Ubuntubot::Util::TempConv;
use Ubuntubot::Util::Scramble;
use Ubuntubot::Util::Unicode;

# modules used by Ubuntu Bot modules (including this one)
use Safe;
use URI::Find::Schemeless;
use CGI; # for Vars
use LWP::Simple ();
use Geo::IP;
use Encode ();
use Unicode::CharName ();

use DBI;
my $lnk;
my $ban;


sub tell
{

	my ($self, $to_who, $from_who, $chan, $keyword) = @_;

	defined ( my $info = $self->fact(GET => $keyword) ) or $self->act( SAY => $chan, "aš nežinau apie $keyword, $from_who ! Tai kaip aš galiu meluot ?" ), return;
	# testai
  my $levelis = $self->user_access( GET_USER_DATA => $from_who, "level" );
	#$self->act( SAY => $to_who,   qq(jo access levelis yra $lolas));
	if (($self->user_access( CHECK_MASK => $from_who)) and ($self->user_access( GET_USER_DATA => $from_who, "level" ) >= 1)) {
  $self->act( SAY => $to_who,   qq($from_who norėjo jog tu žinotum apie "$keyword": $info) );
	$self->act( SAY => $from_who, qq(pasakiau $to_who: $info) );
  } else {
  if ($chan =~/\#/i) {
  $self->act( SAY => $chan,   qq($to_who: $info) );
	#$self->act( SAY => $chan, qq(pasakiau $to_who: $info) );
	} else {
  $self->act( SAY => $chan, qq(Geriau rašyk kanale) );
  }
  }
}


sub host
{

	my ($self, $type, $addr) = @_;
	Ubuntubot::Util::Host->new($type, $addr);

}


sub math
{

	my ($self, $expr) = @_;
	Ubuntubot::Util::Math->new($expr);

}


sub tempconv
{

	my ($self, $temp) = @_;
	Ubuntubot::Util::TempConv->new($temp);

}


sub unicode
{

	my ($self, $char) = @_;
	Ubuntubot::Util::Unicode->info($char);

}


sub scramble
{

	my ($self, $text) = @_;
	Ubuntubot::Util::Scramble->scramble($text);

}


sub magic8ball
{

	my $balls = [ "Paklausk vėliau", "Neimanoma turbūt", "Hmm, žinoma", "Mesk monetą", "Neklausk manęs", "Tu niekada negali žinoti", "Ne", "Taip" ];
	return "Magiškas 8ball sako: " . $balls->[rand 8];

}


sub retard
{

	my ($self, $who) = @_;
	
	my $saying =  [ "WHY USE UBUNTU!?  WINDOWS IS FASTAR?!?!?",
			 		"How I can play teh games wit ubuntu?!?!",
					"CAN I BORROW SOME OF UR BRAINPOWER PLZ? I DONT WANNA LERN LENUGZ!@!",
				 	"Hi, can I paste this very long script I downloaded and let you fix it for me plz??",
					"OMG u r teh gr8est 10x thx k bye!" ] -> [rand 5];

	if (defined $who)
	{

		return "<$who> $saying";

	}
	else
	{

		return $saying;

	}

}

# version information
sub version {
my ($self) = @_;
my $version = $self->bot_cfg("VER");
my $lines = `./lines`;
return "Dabartinė versija: $version, Perl: $], Kodo eilučių: $lines";
}

sub os {
my ($self) = @_;
my $os = `uname -rs`;
return "OS: $os";
}

sub statsai {
my ($self) = @_;
#my $laikas = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime);
my $time_taken = time - $self->get("start_time");
my @parts = gmtime($time_taken);
my $plines = $self->get("processed_lines");
my $pquestions = $self->get("processed_questions");
return sprintf ("Veikiu: %1dd %1dh %1dm %1ds nuo paleidimo perprocesinau %s eilučių ir %s užklausų\n",@parts[7,2,1,0],$plines,$pquestions);
}

sub uptimeas
{
my ($self) = @_;
my $uptaimas = qx("uptime");
return $uptaimas;
}


sub fortune
{

	my ($self) = @_;

	my $fortune_prog = $self->bot_cfg("FORTUNE_PROG");

	return "FORTUNE_PROG nenurodytas konfigūracijoje. Aš negaliu rodyti fortūnų.  Pranešk mano sąvininkui kad sutaisytų šitą errorą!" unless $fortune_prog;

	my $fortune = qx($fortune_prog);

	$fortune =~ s/\s*\n\s*/ /g;

	return $fortune;

}


{

# used for caching previously shortened URLs
my %url_cache;

sub shorten_url
{

	my ($self, $url) = @_;
	
	my $short_url;

	# which services will be used
	my @services = qw(WWW::Shorten::Metamark WWW::Shorten::SnipURL WWW::Shorten::BabyURL WWW::Shorten::TinyURL);
	
	# has this url been shortened previously by the bot?
	if (exists $url_cache{$url})
	{

		return $url_cache{$url};

	}
	else
	{

		# try very hard to make a shorter link
		# try all services before giving up
		
		SERVICE: for my $service (@services)
		{

			# needs eval to require something in a $scalar
			eval "require $service";
			
			no strict 'refs';
			
			local $SIG{ALRM} = sub { goto SERVICE };
			alarm(4);	# five second timeout

			$short_url = &{"${service}::makeashorterlink"}($url);

			alarm(0);	# turn off
			
			use strict 'refs';
			
			# success! a shorter link was made
			last if defined $short_url and $short_url ne $url;
			
			# otherwise keep looping
			
		}
		
		# cache only if $short_url doesn't match and if $short_url is defined
		if (defined $short_url and $short_url ne $url)
		{

			$url_cache{$url} = $short_url;

		}

		return defined $short_url ? $short_url : $url;

	}

}

}


sub ignore_user_check
{

	# check if a user is ignored

	my ($self, $who) = @_;

	return $self->contains($who, [split /\s+/, $self->bot_cfg("IGNORED_USERS") || ""]);

}   

sub ignore_channel_check
{

	# check if all users on a channel are ignored

	my ($self, $who) = @_;

	return $self->contains($who, [split /\s+/, $self->bot_cfg("IGNORED_CHANNELS") || ""]);

}   

sub contains
{   

	# case insensitive match

	my ($self, $thing, $aref) = @_;

	$thing = lc $thing;

	for (@$aref)
	{

		$thing eq lc $_ and return 1;

	}

	return;

}


# code stolen from some shit bot :|||||
sub karma_check
{

	# look for karma in a string
	
	my ($self)	= @_;
	local $_	= $self->get("query");
	
	# don't call someone an idiot more than once per line
	# if they try to "karma themselves
	my $called_an_idiot = 0;
	
	# plus or minus regex - makes below reges cleaner
	my $pm = qr/\+{2,}|-{2,}/;
	
	# match (foo bar)++ and foobar++, respectively
	# match repeatedly; "foobar++ foobar++" will incriment foobar twice
	while ( /(?:\(\s*(.+)\s*\)($pm))|(?:(\S+?)($pm))/g )
	{

		my ($thing, $plus_or_minus) = ($1 || $3, $2 || $4);

		# add to or subtract from
		my $add_or_sub = index($plus_or_minus, "+") != -1 ? "ADD" : "SUBTRACT";
		
		# is someone trying to karma themself?
		# if so, let them know that is a no-no
		# but only tell them once
		if (lc $thing eq lc $self->get("user_nick") and $add_or_sub eq "ADD" and not $called_an_idiot)
		{

			$called_an_idiot = 1;
			
			$self->karma(SUBTRACT => $thing);
			
			my $chan = $self->get("chan");
			$self->act( SAY => $chan, "Kas per idijotai naudoja karmas patys?  Tu kažkoks idijotas!"); 
			
		}
		else
		{
		
			$self->karma($add_or_sub, $thing);

		}
			
	}

}

sub save_all_urls {
# hack to save all urls (channel, nick, text)
# we will save all urls in database

my ($self, $chan, $nick, $text) = @_;

	my @uris;

	my $finder = URI::Find::Schemeless->new( sub { push @uris, shift } );
	$finder->find(\$text);

  
	# store only the first URL seen in the channel
	if ($uris[0])
	{

    _connect_dbs($self) unless defined $lnk;    
    my $laikas = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $query = "INSERT INTO linkai (linkas, kanalas, nick, data) VALUES (?, ?, ?, ?)";
    my $stb = $lnk->prepare($query);
    $stb->execute($uris[0], $chan, $nick, $laikas);


	}
}

sub chans_action
{
my ($self, $chan, $user, $action) = @_;

return unless defined $chan and $user and $action;

$self->set(WHOIS_CHAN => $chan);
$self->set(WHOIS_NICK => $user);
$self->set(WHOIS_ACTION => $action);
$self->act(RAW_COMMAND => "WHOIS $user");

return;
}

sub get_chans
{
my ($self, $line) = @_;
# chans_action callback
# called directly from main parser engine

my $nick = $self->get("WHOIS_NICK");
my $chan = $self->get("WHOIS_CHAN");
my $action = $self->get("WHOIS_ACTION");

return unless defined $nick and $chan and $action;

return unless ($nick ne $self->bot_cfg("NICK")); 

$self->log_msg("get_chans veikia su $nick $chan $action");

for ($action) {
		if    (/badcheck/)  { $self->blacklisted_chans($nick, $chan, $2) if ($line =~ /^:.* 319 .* (\Q$nick\E) :(.*)/i); }
		elsif (/ban/)       { $self->act(BAN => $chan, "$1") if ($line =~ /^:.* 319 .* .* .* (.*) .* (\Q$nick\E) .*/i); }
		elsif (/unb/)     { $self->act(UNBAN => $chan, "*!*\@$1") if ($line =~ /^:.* 319 .* .* .* (.*) .* (\Q$nick\E) .*/i); }
		else                { $self->log_msg("Something bad happend with get_chans function it seems to be no correct action parameter"); }
	}

$self->set(WHOIS_NICK => "");
$self->set(WHOIS_CHAN => "");
$self->set(WHOIS_ACTION => "");


}

sub blacklisted_chans
{
my ($self, $nick, $chan, $chans) = @_;
return unless defined $nick and $chan and $chans;
_connect_bans_db($self) unless defined $ban;
return unless ($nick ne $self->bot_cfg("NICK"));

$chans =~ s/[@,~,+,&,%]#/#/g; 
#$self->act(SAY => $chan, "Nicko $nick kanalai: $chans");
my @chan_mass = split(/ /, $chans);
# we will check against badchans database table
my $query = "SELECT chans, reason, action from badchans";
my $badchans = $ban->prepare($query);
$badchans->execute();
my %data;
  while (my @row = $badchans->fetchrow_array) {
    #$self->log_msg("$row[0]\n");
      foreach my $val (@chan_mass) {
           #print "$val\n";
           if ($row[0] =~ m/(\Q$val\E)/i) { @data{qw/chans reason action/} = @row; last; }
      }

    }
return unless defined $data{reason};   

$self->log_msg("Nickas $nick yra bad kanaluose. Darom tvarka!");

if ($data{action} eq "kick") {
$self->act( KICK => $chan, "$nick $data{reason}");
return;
}
elsif ($data{action} eq "kickban") {
$self->kick_banned($chan, $nick, "none", $data{reason});
return;
}
elsif ($data{action} eq "tempban") {
$self->add_banana($nick, "badchan", $chan , $data{reason});
return;
} else {
$self->act( SAY => $chan, "$nick $data{reason}");
return;
}


}

sub get_who
{
my ($self, $line) = @_;
# who_action callback
# called directly from main parser engine

my $nick = $self->get("WHO_NICK");
my $chan = $self->get("WHO_CHAN");
my $action = $self->get("WHO_ACTION");

return unless defined $nick and $chan and $action; 

$self->log_msg("get_who veikia su $nick $chan $action");

for ($action) {
		if    (/printwho/)  { $self->act(SAY => $chan, "Nicko $nick hostas: $1") if ($line =~ /^:.* 352 .* .* .* (.*) .* (\Q$nick\E) H.*/i); }
		elsif (/ban/)       { $self->act(BAN => $chan, "$1") if ($line =~ /^:.* 352 .* .* .* (.*) .* (\Q$nick\E) H.*/i); }
		elsif (/unb/)     { $self->act(UNBAN => $chan, "*!*\@$1") if ($line =~ /^:.* 352 .* .* .* (.*) .* (\Q$nick\E) H.*/i); }
		else                { $self->log_msg("Something bad happend with get_who function it seems to be no correct action parameter"); }
	}

$self->set(WHO_NICK => "");
$self->set(WHO_CHAN => "");
$self->set(WHO_ACTION => "");

}

sub who_action
{
# this function sets variables for get_who function that are called from callback
my ($self, $chan, $user, $action) = @_;

return unless defined $chan and $user and $action;

$self->set(WHO_CHAN => $chan);
$self->set(WHO_NICK => $user);
$self->set(WHO_ACTION => $action);
$self->act(RAW_COMMAND => "WHO $user");

return;

}

sub voice_user 
{
my ($self, $chan, $nick, $hostmask) = @_;


return unless ($nick ne $self->bot_cfg("NICK"));
return unless defined $chan and $nick and $hostmask;
#return unless $self->user_access( GET_USER_DATA => $nick, "level" ) == 3;
#return unless $self->user_access( GET_USER_DATA => $nick, "host" ) == 3;
return unless ($self->user_access( GET_USER_DATA => $nick, "hostmask" ) eq $hostmask) and ($self->user_access( GET_USER_DATA => $nick, "level" ) == 3);

$self->log_msg("Atejo moderatorius $nick i kanala $chan duodam jam voice");
$self->act ( SET_MODE => "$chan +v $nick" );
}


sub kick_banned
{
# We will bad those assholes!
my ($self, $chan, $nick, $hostmask, $reason) = @_;
# we will define $reason wariable if its not set because ban without reason is not possible
$reason = "BANNED!" unless defined $reason;
$self->log_msg("Banning $nick @ $hostmask from $chan with reason $reason");
$self->act( BAN => $chan, "$nick");
# needs to implement fully functional hostmask bans from bananas command
$self->act( BAN => $chan, "$hostmask") unless ($hostmask eq "none");
$self->who_action($chan, $nick, "ban") if ($hostmask eq "none");
$self->act( KICK => $chan, "$nick $reason");
}

sub _get_ban
{
my ($self, $bananas) = @_;
_connect_bans_db($self) unless defined $ban;
my $query = "SELECT nickas FROM bananai where lower(nickas) = lower(?)";
	my $banas = $ban->prepare($query);
	$banas->execute($bananas);
	return $banas->fetchrow_array;
}

sub _get_ban_host
{
my ($self, $bananas) = @_;
_connect_bans_db($self) unless defined $ban;
my $query = "SELECT nickas, hostas FROM bananai where lower(nickas) = lower(?)";
my $banas = $ban->prepare($query);
$banas->execute($bananas);
my %data;
@data{qw/nickas hostas/} = $banas->fetchrow_array;
return unless defined $data{hostas};
return $data{hostas};
}

sub del_banana
{
my ($self, $nick, $chan) = @_;

  #$self->log_msg("test del_banana function");
	$self->act( UNBAN => $chan, $nick);
	$self->act( UNBAN => $chan, _get_ban_host($self, $nick)) if defined _get_ban_host($self, $nick );
	$self->who_action($chan, $nick, "unb");
  unless (defined _get_ban($self, $nick))
	{
		$self->act(SAY => $chan, ":O");
		return;

	}
	
	my $query = "DELETE from bananai WHERE lower(nickas) = lower(?)";
	my $bananai = $ban->prepare($query);
	$bananai->execute($nick);
	$self->act(SAY => $chan, ";-)");
	

}

sub silent_banana 
{
my ($self, $nick, $host, $reason, $who, $chan) = @_;
_connect_bans_db($self) unless defined $ban;
$self->log_msg("Adminas $who pridejo silent bana nickui su reasonu $reason");

if (defined _get_ban($self, $nick))
	{
	  $self->log_msg("$nick jau yra užbananintas");
		$self->act( SAY => $chan, ":-(");
		return;
	}
  my $data = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime);
	my $query = "INSERT INTO bananai (nickas, hostas, uzdejo, data, reasonas) VALUES (?, ?, ?, ?, ?)";
	my $bananaz = $ban->prepare($query);
	$bananaz->execute($nick, $host, $who, $data, $reason);
	$self->act( SAY => $chan, ";-)");

	return;


}

sub add_banana
{
# now we will add some bananas to banana union!
# ( $to_nick, $who, $chan, $reason );
my ($self, $to_nick, $who, $chan, $reason) = @_;
_connect_bans_db($self) unless defined $ban;
$self->log_msg("Adminas $who pridejo bana nickui $to_nick kanale $chan su reasonu $reason");

if (defined _get_ban($self, $to_nick))
	{
	  $self->log_msg("$to_nick jau yra užbananintas");
		$self->act( SAY => $chan, ":-(");
		return;
	}
  my $data = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime);
	my $query = "INSERT INTO bananai (nickas, hostas, uzdejo, data, reasonas) VALUES (?, ?, ?, ?, ?)";
	my $bananaz = $ban->prepare($query);
	# needs bugfix to implement hostmask addition
	my $hostas = "none";
	
  if ($who =~ /spamfiltras/i) {
  my @splitas = split(':',$who);
  $hostas = $splitas[1];
  $who = $splitas[0]; 
  } 
	
  $bananaz->execute($to_nick, $hostas, $who, $data, $reason);
  
  $self->kick_banned($chan, $to_nick, $hostas, $reason);
	$self->act( SAY => $chan, ";-)");
	

	return 1;


}

sub check_spam {
my ($self, $chan, $nick, $hostmask, $search_str) = @_;
_connect_bans_db($self) unless defined $ban;

# check for users and other things to detect

return unless ($nick ne $self->bot_cfg("NICK"));
return unless $chan and $nick and $hostmask and $search_str;
return if ($self->user_access( VALIDATE => $nick, 1));	
#return if ($self->user_access( GET_USER_DATA => $nick, "level" ) >= 1);


my ($first, $last);

	# check for anchor in front, strip if exists
	$first = $search_str =~ s/^\^// ? "" : "%";

	# same with anchor at end of string
	$last = $search_str =~ s/\$$// ? "" : "%";

	# quote...
	my $quoted_search_str = "";
	
	# but then take out the first and last '
	#$quoted_search_str =~ s/'(.+)'/$1/;
	my $query = "SELECT spam, action, reason from spamfilter WHERE lower(spam) like ?";
	my $spam = $ban->prepare($query);
	$spam->execute("$first$quoted_search_str$last");
  my %data;
  while (my @row = $spam->fetchrow_array) {
    #print "$row[0]\n";
    if ($search_str =~ m/($row[0])/) {
    #print "tinka $row[0]";
    @data{qw/spam action reason/} = @row;
    last; 
    }
}    

return unless defined $data{spam};
 
if (quotemeta($search_str =~ /($data{spam})/i)) {
$self->log_msg("aptiktas spamas kanale $chan spameris $nick @ $hostmask spamo zinute $search_str pagal paterna $data{spam} darom veiksma $data{action}");

if ($data{action} eq "kick") {
$self->act( KICK => $chan, "$nick $data{reason}");
return;
}
elsif ($data{action} eq "kickban") {
$self->kick_banned($chan, $nick, $hostmask, $data{reason});
return;
}
elsif ($data{action} eq "tempban") {
$self->add_banana($nick, "spamfiltras:$hostmask", $chan , $data{reason});
return;
} else {
$self->act( SAY => $chan, "$nick $data{reason}");
return;
}

}

#$self->log_msg("aptiktas spamas kanale $chan spameris $nick @ $hostmask spamo zinute $search_str pagal paterna $data{spam}"), $self->kick_banned($chan, $nick, $hostmask, $data{reason})
#if quotemeta($search_str =~ /($data{spam})/i);
}

sub check_banned 
{
my ($self, $chan, $nick, $hostmask) = @_;
_connect_bans_db($self) unless defined $ban;
my %data;
my $query = "SELECT nickas, hostas, reasonas FROM bananai where nickas = ? or hostas = ?";
my $banned_user = $ban->prepare($query);
$banned_user->execute($nick, $hostmask);
@data{qw/nickas hostas reasonas/} = $banned_user->fetchrow_array;

return unless ($data{hostas} or $data{nickas}); 

$self->kick_banned($chan, $nick, $hostmask, $data{reasonas})
#$self->log_msg("uzbanintas $data{nickas} hostas $data{hostas} reasonas $data{reasonas}")
if ($data{hostas} eq $hostmask) or ($data{nickas} eq $nick);
}

sub _connect_dbs
{
        my ($self) = @_;

        defined( my $db_file = $self->bot_cfg("LINKS_DB") ) or die
                sprintf "Fatal Error: LINKS_DB needs to be defined in %s\n", $self->bot_cfg("CONFIGFILE");

        $lnk = DBI->connect("dbi:SQLite(RaiseError=>1):$db_file");
    
}

sub _connect_bans_db
{
        my ($self) = @_;

        defined( my $db_file2 = $self->bot_cfg("BANS_DB") ) or die
                sprintf "Fatal Error: BANS_DB needs to be defined in %s\n", $self->bot_cfg("CONFIGFILE");
                
        $ban = DBI->connect("dbi:SQLite(RaiseError=>1):$db_file2");

}


sub uri_in_msg_check
{

	my ($self, $text, $chan) = @_;

	my @uris;

	my $finder = URI::Find::Schemeless->new( sub { push @uris, shift } );
	$finder->find(\$text);

	# store only the first URL seen in the channel
	if ($uris[0])
	{

		$self->chan_url( SET => $chan, $uris[0] );

	}

}


{

# scope appropriately so variable will remain between calls to chan_url
my %chan_data;

sub chan_url
{

	my $self = shift;
	my $do = lc shift;
	
	if ($do eq "set")
	{

		my ($chan, $url) = @_;
		$chan_data{$chan} = $url;

	}
	elsif ($do eq "get")
	{

		my ($chan) = @_;
		return $chan_data{$chan};
		
	}
	else
	{

		die "blogas do parametras '$do'";

	}

}

}


# do reverse lookups on phone numbers
sub revlookup
{

	my ($self, $raw_num) = @_;

	# make a copy to work on
	my $phone_num = $raw_num;
	
	# be able to specify numbers using letters, like "702-BEDTIME"
	$phone_num =~ tr/abcdefghijklmnopqrstuvqxyzABCDEFGHIJKLMNOPQRSTUVQXYZ/2223334445556667777888999922233344455566677778889999/;
	
	# delete all non-digits from the string;
	$phone_num =~ tr/0-9//cd;

	my ($area_code, $prefix_suffix) = $phone_num =~ /^1?(\d{3})(\d{7})$/ or return "Bad number: $raw_num\n";

	my $html_results = LWP::Simple::get("http://www.phonenumber.com/10006/search/Reverse_Phone?npa=$area_code&phone=$prefix_suffix");
	
	defined $html_results or return "That function is broken for now, try back later (LWP couldn't download from the phonenumber.com website, or encountered an error)";
	
	# rip the information out
	my ($params) = $html_results =~ /^\s*oas_query\s*=\s*'\?(.+?)'/m or return "That function is broken for now, try back later (regex failed)";
	
	# use the CGI module to turn something like "foo=bar&zig=zag" into a hash
	my %params = CGI->new($params)->Vars;

	return "No results for '$raw_num'.  It's probably unlisted" unless $params{_RM_HTML_STATE_ESC_};

	# remove escapes in $params{_RM_HTML_PHONE_ESC_} so the number looks preetier
	$params{_RM_HTML_PHONE_ESC_} =~ y!\\!!d;
	
	return "Phonenumber.com listing for $params{_RM_HTML_PHONE_ESC_}: $params{_RM_HTML_FIRST_ESC_} $params{_RM_HTML_LAST_ESC_}, $params{_RM_HTML_ADDRESS_ESC_}, $params{_RM_HTML_CITY_ESC_}, $params{_RM_HTML_STATE_ESC_} $params{_RM_HTML_ZIP_ESC_}\n";

}


sub geoip
{

	my ($self, $record) = @_;
	
	my $g = Geo::IP->open("/home/devnull/ubuntu-bot/botas/data/GeoIP.dat") or die "problem opening GeoIP database: $@ $!";
	
	my $result;
	
	if ($record =~ /[^0-9.]/)
	{
	
		$result = $g->country_name_by_name($record);

	}
	else
	{
		
		$result = $g->country_name_by_addr($record);

	}

	return $result ? "Šalis: $result" : "Atsiprašau, tačiau duombazėje nepavyko aptikti";

}

sub jargon
{

	my ($self, $term) = @_;

	if (defined (my $filename = $self->bot_cfg("JARGON_FILE")))
	{

		open my $fh, $filename
			or return "Problema skaitant %entries (blogas JARGON_FILE įrašas konfige?): $!";

		$term = lc $term;
		
		while (<$fh>)
		{

			
			my ($real_term, $entry) = /^(.+?) => (.+)\s*$/; # grab the term

			if (lc $real_term eq $term)
			{

				# hack text off in extensive entries
				$entry =~ s/^(.{270}).*$/$1 (etc.)/ if length $entry > 280;
				
				return "Žargonas \"$real_term\" yra $entry";
				
			}

		}

		# if we got here, the term wasn't found
		return "Terminas \"$term\" nerastas žargonų faile";

	}
	else
	{

		return "Nėra JARGON_FILE įrašo konfige";

	}

}

1;
