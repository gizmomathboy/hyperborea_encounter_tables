#!/usr/bin/env perl
# PODNAME: roland
# ABSTRACT: roll and print results
use strict;
use warnings;

#use lib 'lib';

use Getopt::Long::Descriptive;
use Roland::Hub;
use Cpanel::JSON::XS;

use v5.24;

my ($opt, $usage) = describe_options(
  '%c %o <table>',
  [ 'manual|m',     'enter die rolls manually' ],
  [ 'debug|d',      'show all die rolling activity' ],
  [ 'options|o=s%', 'options to pass to the table' ],
);

my $hub = Roland::Hub->new({
  manual => $opt->manual,
  debug  => $opt->debug,
});

$usage->die unless $ARGV[0];

my $table = shift @ARGV;

our $base = q(/media/jkline/moredata/jkline/blackevil/dnd/astonishing-swordsmen-and-sorcerors-of-hyperborea/resources/encounter-tables/hyperborean_encounter_tables);

say "rolling on $table" if $hub->debug;

my $file_path = qq($base/$table);
my $result = $hub->load_table_file($file_path)->roll_table($opt->options)->as_block_text;

if ( $result =~ m/[a-z]/ ) {
  say $result;
}
else {
  say qq($result needs a terrain);
  check_location_terrains($result);
}
exit(0);
#####
sub get_encounter_data {
  my $encounter_data = q(hyperborean_encounter.json);
  my $file = qq($base/$encounter_data);
  local $/=undef;
  my $terrains = YAML::Load(<DATA>);
  my ($selection) = get_user_input($terrains);
}
###
sub check_location_terrains {
  my ($table) = @_;
  $table = lc $table;
  local $/=undef;
  my $terrains = YAML::Load(<DATA>);
  my ($selection) = get_user_input($terrains);

  my $terrain_table = $terrains->[$selection];
  #say qq(terrain_table: $terrain_table);
  #say qq(base/terrain/$terrain_table/$table);
  my $file_path = qq($base/terrain/$terrain_table/$table);
  my $result = $hub->load_table_file($file_path)->roll_table($opt->options)->as_block_text;
  say $result;
}
###
sub get_user_input{
  my ($terrains) = @_;
  #say q(Select a terrain type: );

  while ( my ($index, $terrain)  = each $terrains->@* ) {
    say qq($index: $terrain);
  }

  #my $terrain_choice = prompt q(Pleae select terrain type:), -num;
  #
  print q(Please select terrain (by number): );
  my $selection = <STDIN>;
  chomp $selection;
  chop $selection;
  #say qq('$selection' selected);
  return($selection);
}
__DATA__
- bluffs_hills
- bluffs_hills_glaciated
- city
- desert_sandy
- desert_steppe
- forest
- grasslands_plains_scrublands
- mountains
- mountains_glaciated
- swamp_marsh_wetlands
- town_village
- tundra
- watercourses_lakes_and_rivers
- watercourses_sea
