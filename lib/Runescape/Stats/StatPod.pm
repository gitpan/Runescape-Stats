##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
##                                                                           
##   Runescape::Stats - Return type of Runescape::Stats data accession  
##                      methods
##                                                                           
##   Runescape copyright (c) Jagex Software Ltd.                             
##   This file copyright (c) MadCoder Development. (http://www.madcoder.net) 
##                                                                           
##   This module is free software; you can redistribute or modify it under   
##   the terms of Perl's Artistic License.                                   
##                                                                           
##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
package Runescape::Stats::StatPod;

#  A very, very simple module through which Runescape::Stats
#  returns data from it's stat retrieval functions. 
# 
#  Each StatPod holds information about one stat group, and 
#  has accessor functions for that data.
#
#  There is no new() or method of self-blessing. Stats.pm blesses
#  an array into a StatPod, and this file merely defines an automatic
#  accessor function.

my %map = ( name => 0,
	    skill => 1,
	    rank => 2,
	    lvl => 3,
	    level => 3, # synonymic :D
	    exp => 4,
	    experience => 4,
	    xp => 4 );


sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/^.*:://;
    return $self->[$map{$AUTOLOAD}];
}

1;

__END__

=head1 NAME

Runescape::Stats::StatPod - A very, very simple module through which Runescape::Stats retuns data from it's stat retrieval functions.

=head1 SYNOPSIS

Runescape::Stats::StatPod items are created and returned by the getStat() and getAllStats() functions of Runescape::Stats.

For example: $statpod = $statsobject->getStat($username, $skill);

Each StatPod has seven accessor functions:

=over 

=item *

$statpod->name

Returns username of user whose stats are within this StatPod.

=item *

$statpod->skill

Returns name of Runescape skill which contains these stats for this user.

=item * 

$statpod->lvl and $statpod->level

Synonymic functions which both return the level of the specified user in the specified skill.

=item *

$statpod->rank

Returns the rank of the specified user in the specified skill.

=item * 

$statpod->xp, $statpod->exp, and $statpod->experience

Synonymic functions which return the experience of the specified user in the specifed skill.

=back

=head2 What if the user doesn't appear in the stat table?

The StatPod accessor methods for rank, level, and experience will all return undef. If any one of them returns undef, you can assume that the rest will be due to the logic used within Runescape::Stats.

=head1 AUTHORS

Designed, created, and developed by Ben Ullian : http://www.madcoder.net

=head1 URL

Information on using this module will soon be available on http://www.madcoder.net

=cut
