##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
##
##   Runescape::Stats - A persistant, cached, and object-oriented interface
##                      to runescape hiscores.
##
##   Runescape copyright (c) Jagex Software Ltd.
##   This file copyright (c) MadCoder Development. (http://www.madcoder.net)
##
##   This module is free software; you can redistribute or modify it under
##   the terms of Perl's Artistic License.
##
##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

package Runescape::Stats;
use strict;
use Runescape::Stats::StatPod;
use LWP::Simple;
use Storable qw(lock_nstore lock_retrieve);

use vars qw($VERSION);
$VERSION = "0.03";

my $skills = {};
$skills->{byNumber} = {0 => 'overall', 1 => 'fighting', 2 => 'ranged',
		       3 => 'prayer', 4 => 'magic', 5 => 'cooking', 
		       6 => 'woodcutting', 7 => 'fletching', 8 => 'fishing', 
		       9 => 'firemaking', 10 => 'crafting', 11 => 'smithing', 
		       12 => 'mining', 13 => 'herblaw', 14 => 'agility', 
		       15 => 'thieving'};
$skills->{byName} = {reverse(%{$skills->{byNumber}})};

sub new {
    my $type = shift;
    my $givenName = shift;
    my $self = {
	Filename => $givenName,
	Timeout => 20000, # default of 20,000 second cache longevity.
	IsPersistant => 1,
    };
    bless($self, $type);
    if (-e $givenName) { # File of given name exists
	$self->loadData;
    } elsif ($givenName) { # Defined, but doesn't exist
	$self->{Data} = {};
	$self->saveData;
	$self->loadData;
    } else { #non-persistant
	$self->{IsPersistant} = 0;
	$self->{Data} = {};
    }
    return $self;
}

sub getAllStats {
    my $self = shift;
    my $user = shift;
    my @return;
    foreach (keys(%{$skills->{byName}})) {
	push @return, $self->getStat($user, $_);
    }
    return @return;
}

sub getStat {
    my $self = shift;
    my $user = lc(shift);
    my $skill = lc(shift);
    my $stat = {};
    $user =~ s/ /_/g;   
    if ($skill =~ /[0-9]/g) {
	$skill = &num2name($skill);
    }
    my $findViaWeb = 0;
    $self->loadData; # load now for freshest statcache.
    if (defined $self->{Data}{$skill}{$user}) {
	if (time() - $self->{Data}{$skill}{$user}{atime} > $self->{Timeout}) {
	    $findViaWeb = 1;
	}
    } else {
	$findViaWeb = 1;
    }
    $self->fillInCache($user, $skill) if ($findViaWeb);
    my $rtnAry;
    if ($self->{Data}{$skill}{$user}{NotInTable}) { $rtnAry = []; } 
    else { $rtnAry = $self->{Data}{$skill}{$user}{stat}; }

    # StatPod Creation... [name,skill,rank,lvl,exp]
    return bless([$user, $skill, (@$rtnAry)], 'Runescape::Stats::StatPod');
}

sub fillInCache {
    # returns 1 if successfully filled in cache.
    # returns 0 if failure.
    my $self = shift;
    my $user = shift;
    my $skillName = shift; #skill name -- the perlish way
    my $skillNum = &name2num($skillName);
    my $html = get('http://www.runescape.com/hiscoreuser.cgi?username='.$user.'&category='.$skillNum);
    my $time = time();
    die("Did not recieve stat HTML!!") unless $html;
    $self->loadData; # update now to hopefully avoid race conditions
    if ($html =~ /not appear in the/im) {
	$self->{Data}{$skillName}{$user} = {
	    atime => $time,
	    NotInTable => 1, 
	};
    } else {
	## Parse Table.
	my @masterTable;
	while ($html =~ /^([^<]+?)<br>$/img) {
	    push @masterTable, $1;
	}
	return 0 unless ((scalar(@masterTable) % 4) == 0);
	my $splindex = scalar(@masterTable) / 4;

	for (my $i=0; $i<$splindex; $i++) {
	    my @row = ();
	    for (my $j=0; $j<=3; $j++) {
		push @row, $masterTable[($j*$splindex)+$i];
	    }
	    $self->{Data}{$skillName}{$row[1]} = {
		atime => $time,
		stat => [$row[0],$row[2],$row[3]],
	    };
	}
    }
    $self->saveData; 
    return 1;
}

sub loadData {
    my $self = shift;
    if ($self->{IsPersistant}) {
	$self->{Data} = lock_retrieve($self->{Filename}) or die ("Could not update from stats database, quitting");
    }
}

sub saveData {
    my $self = shift;
    if ($self->{IsPersistant}) {
	lock_nstore($self->{Data}, $self->{Filename}) or die ("Could not save new stats database, quitting");
    }
}

sub clearCache {
    my $self = shift;
    $self->{Data} = {};
}

sub setCacheTimeout {
    my $self = shift;
    my $time = shift;
    return unless $time;
    $self->{Timeout} = $time;
}

sub num2name {
    my $number = shift;
    return $skills->{byNumber}{$number};
}

sub name2num {
    my $name = lc(shift);
    return $skills->{byName}{$name};
}
1;

__END__

=head1 NAME

Runescape::Stats - A persistent, cached, and object-oriented interface to Runescape Hiscores.

=head1 SYNOPSIS

    use Runescape::Stats;

    ## Persistent Constructor    
    my $obj = new Runescape::Stats('filename');

    ## ..Or Non-Persistent Constructor (Does not save cache to file)
    my $obj = new Runescape::Stats;

    my $statResult = $obj->getStat($username, $skill);
    print $statResult->level;

    my @statResults = $obj->getAllStats($username);
    print $_->level foreach (@statResults);

=head1 DESCRIPTION

This is Runescape::Stats. It was created to enable perl scripts to easily interface to the Jagex hiscores tables and use them as a data source. Not only does it maintain a per-object cache (stats are valid for a certain [settable] amount of time), but it also features the ability to read and write its cache to Storable files by passing a filename to the constructor. By saving the cache, multiple applications can share one cache file, avoiding system-wide repeated lookups. It also is able to mass-harvest all found Stats on any hiscore page, including the users which surround a queried user. This enables the cache to contain preliminary data for users that have not even been searched for -- data which speeds up requests and minimizes Jagex server load should those other users ever be searched for.

Runescape::Stats contains two modules:

=over

=item *

Runescape::Stats

This module performs lookups, conversions, and caching, and also implements cache persistence should it be requested. This is the meat of the program and is the only one of these modules that you will manually instantiate.

=item *

Runescape::Stats::StatPod

This small transport module contains very little code. It is used to shuttle resulting stat info back to the calling program from the Runescape::Stats data retrieval methods. This module increases the efficiency of stat retrieval and simplifies the code required to handle the stat data.

=back

Now that you know a little more about Runescape::Stats, let's examine how to use it...

=head1 USING THE MODULE

=head2 Instantiation

To make use of Runescape::Stats, you only need one thing: a Runescape::Stats object. There are two ways to create a Runescape::Stats object, one which prepares it for cache persistence, and the other which disables cache persistence (and may give you a slight speed increase if your cache is large).

=over

=item *

Non-persistent Constructor

Takes no arguments.

    $object = new Runescape::Stats;

=item *

Persistent Constructor

Takes filename of file in which to store persistent cache. This filename can be specified by more that one application which uses Runescape::Stats and they will all share statcaches. 

    $object = new Runescape::Stats("/etc/statcache.data");

=back

Moving on...

=head2 Stat Retrieval

Runescape::Stats objects provide two simple methods for stat retrieval:

=over

=item *

    $object->getStat($username, $skill)

getStat retrieves data for a single user in a particular skill. $username will be automatically cleaned up by Runescape::Stats, so you need not worry about formatting or capitalization. $skill may be any full Sunescape skill name (i.e. 'Smithing'), or any skill number (i.e. 11). Skill names are case-insensitive. getStat returns a single Runescape::Stats::StatPod object.

=item *

    $object->getAllStats($username)

getAllStats executes getStat internally for every known skill and returns an array of the resulting Runescape::Stats::StatPod objects.

=back

=head2 Other Methods

These are methods that generally do not need to be used in a script which utilizes Runescape::Stats:

=over

=item *

loadData()

This method will force a persistent Runescape::Stats object to reload its cache from it's assigned file. The file used is the one passed to the persistent constructor. Has no effect on non-persistent objects.

=item *

saveData()

This method will force a persistent Runescape::Stats object to save its cache to it's assigned file. No effect on non-persistent objects.

=item *

clearCache()

This method will clear the internal object cache. On a non-persistent Runescape::Stats object, this will cause new queries to re-retrieve data from the Jagex tables. In a persistent object, this call will have no effect unless followed by a call to saveData(), as the cache file will be reread before the next query begins.

=item *

setCacheTimeout($timeInSeconds)

This is used on an object-by-object basis to set the length of time (in seconds) before any cached stat expires. Each stat in the cache is flagged with the time retrieved, and if the number of seconds elapsed since then is greater than this setting, that stat will be re-retrieved from the hiscore tables. Default value is 20,000 seconds in new Runescape::Stats objects, which is approximately five and a half hours.

=back

=head1 AUTHORS

Designed, created, and developed by Ben Ullian : http://www.madcoder.net

=head1 URL

Information on using this module will soon be available on http://www.madcoder.net 

=cut
