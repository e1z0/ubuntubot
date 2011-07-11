package Ubuntubot::Util::Scramble;

# UbuntuBot
# Copyright (c) 2009-2011 \dev\null. Licensed under GPLv3 License.



use strict;
use warnings;

use List::Util;

sub scramble
{

	my ($self, $text) = @_;
	
	my $scrambled;
	
	for my $orig_word (split /\s+/, $text)
	{

		# skip words that are less than four characters in length
		$scrambled .= "$orig_word " and next if length($orig_word) < 4;
		
		# get first and last characters, and middle characters
		# optional characters are for punctuation, etc.
		my ($first, $middle, $last) = $orig_word =~ /^['"]?(.)(.+)'?(.)[,.!?;:'"]?$/;
		
		my ($new_middle, $cnt);
	
		# shuffle until $new_middle is different from $middle
		do
		{
		
			# theoretically, this loop could loop forever, so
			# a counter is used

			if ($cnt++ > 10)
			{

				# non-random shuffle, but good enough
				($new_middle = $middle) =~ s/(.)(.)/$2$1/g;
				last;
				
			}
			
			# shuffle the middle letters
			$new_middle = join "", List::Util::shuffle(split //, $middle);

		}
		while ($middle eq $new_middle);
			
		# add the word to the list...
		$scrambled .= "$first$new_middle$last ";

	}

	# remove the single trailing space, and any other space that may have
	# been included in the original string
	$scrambled =~ s/\s+$//;
	
	return $scrambled;

}

1;
