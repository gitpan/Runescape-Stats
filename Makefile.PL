use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME' => 'Runescape::Stats',
	      'PM' => {
		  'Runescape/Stats.pm' => '$(INST_LIBDIR)/Runescape/Stats.pm',
		  'Runescape/Stats/StatPod.pm' => '$(INST_LIBDIR)/Runescape/Stats/StatPod.pm',
	      },
	      'PREREQ_PM' => {
		  'LWP::Simple' => 0,
		  'Storable' => 0,
	      },
	      'VERSION_FROM' => 'Runescape/Stats.pm',
	      'dist' => { 'COMPRESS' => 'gzip' }
	      );
