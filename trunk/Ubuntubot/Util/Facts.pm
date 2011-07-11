package Ubuntubot::Util::Facts;

# UbuntuBot
# Copyright (c) 2009-2011 \dev\null. Licensed under GPLv3 License.

use strict;
use warnings;
use Carp;
use DBI;

my $TABLE = "facts";
my $dbh;

sub fact
{

	my ($self) = @_;

	# connect to db if needed
	_connect_db($self) unless defined $dbh;
	
	# splice the action parameter out of @_
	my $action = lc splice @_, 1, 1;

	my $dispatch =
	{
		get		=> \&_get_fact,
		add		=> \&_add_fact,
		remove	=> \&_remove_fact,
		search	=> \&_search_facts,
	};

	if ( exists $dispatch->{$action} )
	{

		$dispatch->{$action}->(@_);

	}
	else
	{

#		croak "there is no $action action";
    croak "nėra $action veiksmo"

	}	
	
}


sub _get_fact
{

	my ($self, $keyword) = @_;

	my $query = "SELECT val FROM $TABLE where lower(key) = lower(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($keyword);

	return $sth->fetchrow_array;

}


sub _add_fact
{

	my ($self, $keyword, $fact) = @_;

	# is there already an entry for a keyword in the fact database?	
	if (defined _get_fact($self, $keyword))
	{

		$self->set(FACT_MSG => "Pas mane jau yra įrašas $keyword");
		
		return;

	}

	my $query = "INSERT INTO $TABLE (key, val) VALUES (?, ?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($keyword, $fact);
	
	$self->set(FACT_MSG => "įrašas $keyword pridėtas į duombazę");

	return 1;
	
}


sub _remove_fact
{

	my ($self, $keyword) = @_;

	# is the fact in the database?
	unless (defined _get_fact($self, $keyword))
	{

		$self->set(FACT_MSG => "Aš neturiu įrašo $keyword");
		return;

	}

	my $query = "DELETE from $TABLE WHERE lower(key) = lower(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($keyword);
	
	$self->set(FACT_MSG => "įrašas $keyword pašalintas iš duombazės");

	return 1;
	
}


sub _search_facts
{

	my ($self, $search_str) = @_;

	# allowed input		SQL equivalent
	#
	# foo				%foo%
	# ^foo				foo%
	# foo$				%foo

	my ($first, $last);

	# check for anchor in front, strip if exists
	$first = $search_str =~ s/^\^// ? "" : "%";

	# same with anchor at end of string
	$last = $search_str =~ s/\$$// ? "" : "%";

	# quote...
	my $quoted_search_str = $dbh->quote($search_str);
	
	# but then take out the first and last '
	$quoted_search_str =~ s/'(.+)'/$1/;
	
	my $query = "SELECT key from $TABLE WHERE lower(val) like '$first$quoted_search_str$last'";
	my $sth = $dbh->prepare($query);
	$sth->execute();

	my $matches = $sth->fetchall_arrayref;

	return $matches;

}


sub _connect_db
{

	my ($self) = @_;
	
	defined( my $db_file = $self->bot_cfg("FACTS_DB") ) or die
		sprintf "Fatal Error: FACTS_DB needs to be defined in %s\n", $self->bot_cfg("CONFIGFILE");

	$dbh = DBI->connect("dbi:SQLite(RaiseError=>1):$db_file");

}


1;
