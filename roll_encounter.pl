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
our $tokens_ref;
get_tokens();

our $dispatch;
create_dispatch_table();
#p $dispatch;
#exit(0);


#my @locations = map { keys $_->%* } $data->{D}->@*;
#exit(0);

my $letter = prompt 'Choose location starting letter (ABCDEFGHIKLMNOPRSTUVWXYZ):';

my @locations = sort keys $data->{$letter}->%*;
#my $locations_ref = $data->{$letter}->@*;

my $location = prompt 'Select location: ', -number, -menu => \@locations, '>';
#my $location = prompt 'Select location: ', -menu => $locations_ref, '>';

my $terrains_aref = $data->{$letter}{$location}{terrain};

my $terrain;
if ( $terrains_aref->$#* > 0 ) {
  $terrain = prompt 'Select terrain type ', -number, -menu => $terrains_aref, '>';
}
else {
  $terrain = $terrains_aref->[0][0];
}

my $number = prompt 'Select number of encounters:  ', -num;

for ( 1 .. $number ) {
  get_encounter( { letter   => $letter, 
                   location => $location, 
                   terrain  => $terrain,
                 } );
}

exit(0);

sub get_data {
  my $file = q(hyperborean_encounter.yaml);
  my $encounter_file = qq($base/$file);
  my $data = YAML::LoadFile($encounter_file);
  return($data);
}
###
sub get_tokens {
  my $file = q(encounter_tokens.yaml);
  my $encounter_file = qq($base/$file);
  $tokens_ref = YAML::LoadFile($encounter_file);
}
###
sub create_dispatch_table {
  #say q(create_dispatch_table);
   $dispatch = {
     'sub_table'     => \&sub_table,
     'roll'          => \&roll,
     'hunting_party' => \&hunting_party,
   };
}
###
sub get_encounter {
  my ($args_ref) = @_;
  #my ($letter, $location, $terrain) = @_;
  my $letter   = $args_ref->{letter};
  my $location = $args_ref->{location};
  my $terrain  = $args_ref->{terrain};

  my $hub = Roland::Hub->new();

  my $file = $data->{$letter}{$location}{file};

  my $file_path = qq($base/hyperborean_encounter_tables/$file);

  my $result = $hub->load_table_file($file_path)->roll_table()->as_block_text;

  say qq(get_encounter result: $result);

  $args_ref->{result} = $result;
  $args_ref->{hub}    = $hub;

  process_results($args_ref); 
}
###
sub process_results {
  my ($args_ref) = @_;

  my $result = $args_ref->{result};

  for my $regex_token ( $tokens_ref->@* ) {
    my $regex = qr/$regex_token->[0]/;
    my $token = $regex_token->[1];

    #say qq(  regex: $regex, token: $token);

    if ( $result =~ m/$regex/ ) {
      $dispatch->{ $token }->($args_ref);
      last;
    }
  }
  say qq(no matches: $result);
}
###
sub sub_table   {
  my ($args_ref) = @_;

  say qq(  in sub_table);

  my $table   = lc $args_ref->{result};
  my $terrain = $args_ref->{terrain};
  my $hub     = $args_ref->{hub};

  say qq(    table: $table, terrain: $terrain);

  my $file_path = qq($base/hyperborean_encounter_tables/terrain/$terrain/$table);
  my $result = $hub->load_table_file($file_path)->roll_table()->as_block_text;
  $args_ref->{result} = $result;
  process_results($args_ref);
}
###
sub roll {
  my ($args_ref ) = @_;
  say qq(  in roll);

  my $result = $args_ref->{result};
  my $hub    = $args_ref->{hub};

  say qq(    result: $result);

  my @parts = split(/\s+/, $result);
  my $roll = $hub->roll_dice($parts[0]);
  $parts[0] = $roll;
  $result = join(' ', @parts);
  say $result;
}
###
sub hunting_party {
  my ($args_ref) = @_;
  say qq(  in hunting_party);
  say join(',', keys $args_ref->%*);

  my $hub = $args_ref->{hub};

  my $file_path = qq($base/hyperborean_encounter_tables/appendix_tables/hunting_table);
  my $result = $hub->load_table_file($file_path)->roll_table()->as_block_text;

  say $result;
}
