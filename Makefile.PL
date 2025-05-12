use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> "DTP",
	VERSION_FROM	=> 'lib/DTP.pm',
	'dist'		=> {
			     COMPRESS	=> 'gzip -9f',
	      		     SUFFIX	=> 'gz',
	      		     DIST_DEFAULT => 'all tardist',
			   },
        PREREQ_FATAL    => 1,
        PREREQ_PRINT    => 1,
        PREREQ_PM => { 'Data::Dumper'=> 0 }
);
