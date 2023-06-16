use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl Games::ROT",
  "AUTHOR" => "Chris Prather <chris\@prather.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "Test::More" => 0,
    "strict" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Games-ROT",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Games::ROT",
  "PREREQ_PM" => {
	'Feature::Compat::Class' => 0,
	'Term::Screen' => 0,
   },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

