#!/usr/bin/env perl

use strict;
use warnings;

use YAML qw(LoadFile);
use IO::Prompter;
use Data::Printer;
use Roland::Hub;

use v5.24;

our $base = q(/media/jkline/moredata/jkline/blackevil/dnd/astonishing-swordsmen-and-sorcerors-of-hyperborea/resources/encounter-tables);

our $data = get_data();

#say $data->{D}->@*;
#exit(0);

my $letter = prompt 'Choose location starting letter (ABCDEFGHIKLMNOPRSTUVWXYZ):';

#my @locations = sort keys $data->{$letter}->@*;
my $locations_ref = $data->{$letter}->@*;

#my $location = prompt 'Select location: ', -menu => \@locations, '>';
my $location = prompt 'Select location: ', -menu => $locations_ref, '>';

my @terrains = $data->{$letter}{$location}{terrain};

my $terrain;
if ( $#terrains > 0 ) {
  $terrain = prompt 'Select terrain type ', -menu => $terrains[0], '>';
}
else {
  $terrain = $terrains[0][0];
}

my $number = prompt 'Select number of encounters:  ', -num;

for ( 1 .. $number ) {
  get_encounter($letter, $location, $terrain);
}

exit(0);

sub get_data {
  my $file = q(hyperborean_encounter.yaml);
  my $encounter_file = qq($base/$file);
  my $data = YAML::LoadFile($encounter_file);
  return($data);
}
###
sub get_encounter {
  my ($letter, $location, $terrain) = @_;

  #my ($opt, $usage) = describe_options(
    #'%c %o <table>',
    #[ 'manual|m',     'enter die rolls manually' ],
    #[ 'debug|d',      'show all die rolling activity' ],
    #[ 'options|o=s%', 'options to pass to the table' ],
  #);

  my $hub = Roland::Hub->new({
    #manual => $opt->manual,
    #debug  => $opt->debug,
  });

  my $file = $data->{$letter}{$location}{file};
  #say qq(file: $file);
  my $file_path = qq($base/hyperborean_encounter_tables/$file);

  #my $result = $hub->load_table_file($file_path)->roll_table($opt->options)->as_block_text;
  my $result = $hub->load_table_file($file_path)->roll_table()->as_block_text;

  #say qq(raw result: $result);

  if ( $result =~ m/[a-z]/ ) {
  }
  else {
    my $table = lc $result;
    my $file_path = qq($base/hyperborean_encounter_tables/terrain/$terrain/$table);
    $result = $hub->load_table_file($file_path)->roll_table()->as_block_text;
  }

  if ( $result =~ m/\dd\d/ ) {
    my @parts = split(/\s+/, $result);
    my $roll = $hub->roll_dice($parts[0]);
    $parts[0] = $roll;
    $result = join(' ', @parts);
  }
  elsif ( $result =~ m/hunting party/i) {
    my $table = q(hunting_party);
    my $file_path = qq($base/hyperborean_encounter_tables/appendix_tables/$table);
    my $result = $hub->load_table_file($file_path)->roll_table()->as_block_text;
    say $result;
  }
  say $result;
}
