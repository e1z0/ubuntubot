package Ubuntubot::Util::Spell;

# UbuntuBot
# Copyright (c) 2009-2011 \dev\null. Licensed under GPLv3 License.


use strict;
use warnings;

use Text::Aspell;
	
my $speller = Text::Aspell->new;
$speller->set_option(lang => "en_US");

sub spell {

	if ($speller->check($word))
	{
		
		return $word;

	}
	else
	{
		my @suggestions = $speller->suggest($word);
		
		return @suggestions
			? "Couldn't find $word in the dictionary; maybe you meant one of these: @suggestions"
			: "Couldn't find $word in the dictionary, and there are no suggestions for that word.";
	
	}

}

1;
