use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME' => 'Runescape::Stats',
	      'PREREQ_PM' => {
		  'LWP::Simple' => 0,
		  'Storable' => 0,
	      },
	      'VERSION_FROM' => 'lib/Runescape/Stats.pm',
	      'dist' => { 'COMPRESS' => 'gzip' }
	      );
