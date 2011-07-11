package Ubuntubot::Util::Math;

# UbuntuBot
# Copyright (c) 2009-2011 \dev\null. Licensed under GPLv3 License.



# UBUNTU BOT v0.1

use strict;
use warnings;
use Safe;

sub new 
{ 

	my ($self, $expr) = @_;
	
	# return "acceptable operators, grouping characters, and other characters are + - * / ** ^ % ( ) _ x a-z" if tainted($expr);

	# can't start with a /
	return "Blogas sàlyga: negalima pradëti su /" if "/" eq substr $expr, 0, 1;
	
	# perl uses ** for exponents
	$expr =~ s(\^)(**)g;

	# pie
	$expr =~ s/\bpi\b/3.141592653589/ig;
	
	# e
	$expr =~ s/\be\b/2.718281828459/ig;
	
	# don't let perl's vstrings ruin the expression
	return "Dalis sàlygos bus suvirğkinta naudojant Perl'o v-strings'us.  Bandyk dar kartà be mëginimo naudoti v-strings." if $expr =~ /\.\d+\./;

	# create a "safe compartment"
	my $safe = Safe->new;

	# only the following opcodes will be permitted
	$safe->permit_only(qw(
		padany lineseq
		leaveeval entereval const negate
		add subtract multiply divide modulo pow
		preinc postinc predec postdec abs
		abs atan2 cos exp hex int log oct rand sin sqrt
		pushmark list
		));

	# some functions use $_ if no argument is specified, so might as well make sure $_ is empty
	local $_;
	
	# eval $expr in the safe compartment
	my $result = $safe->reval($expr);
	
	# was there an error?  If so, rip out the relevant error message
	# and return it.  Otherwise, return the result of the eval
	if (my ($err_msg) = $@ =~ /^(.+) at \(eval \d+\) line \d+/)
	{

		return "Bloga sàlyga: $err_msg";
		
	}
	else
	{

		return $result;

	}

}

1;
