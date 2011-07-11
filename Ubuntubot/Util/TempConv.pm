package Ubuntubot::Util::TempConv;

# UbuntuBot
# Copyright (c) 2009-2011 \dev\null. Licensed under GPLv3 License.

use strict;
use warnings;

sub new
{
	
	my ($self, $temp) = @_;

	my $kelvin;

	return "too large of a number" if 15 < length $temp;
	
	if ($temp =~ /^([-+]?\d+(?:\.\d+)?)\s*k(?:elvin)?$/i)
	{
		$kelvin = $1

	}
	elsif ($temp =~ /^([-+]?\d+(?:\.\d+)?)\s*c(?:elsius)?$/i)
	{
		
		$kelvin = $1 + 273.15

	}
	elsif ($temp =~ /^([-+]?\d+(?:\.\d+)?)\s*f(?:ah?renheit)?$/i)
	{
		
		$kelvin = 5 / 9 * ($1-32) + 273.15

	}
	else
	{

		return "Bad input. Examples of allowed format for temperature conversions: 100F   32.4C   314K ";

	}

	if ($kelvin < 0)
	{
		
		return "Temperature can't be below absolute zero.";

	}

	return sprintf "%.2f Fahrenheit = %.2f Celsius = %.2f Kelvin\n", 1.8 * ($kelvin - 273.15) + 32, $kelvin - 273.15, $kelvin; 

}

1;
