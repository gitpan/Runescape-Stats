
#########################

use Test::More tests => 6;
sub BEGIN { use_ok('Runescape::Stats') };

#########################

use Runescape::Stats;

my $nonpObject = new Runescape::Stats;
ok( defined($nonpObject) and ref $nonpObject eq 'Runescape::Stats', 'non-persistant new()' );

my $pObject = new Runescape::Stats('stats.test');
ok( defined($pObject) and ref($pObject->{Data}) eq 'HASH', 'persistant new()' );

ok( -e 'stats.test', 'persistant file creation' );

my $statPod = $pObject->getStat('tks', 'cooking');

ok (defined($statPod) and ref $statPod eq 'Runescape::Stats::StatPod', 'StatPod creation');

ok ($statPod->name eq 'tks', 'StatPod data accession');
