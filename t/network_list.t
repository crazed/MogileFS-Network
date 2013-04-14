#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;

use MogileFS::Network::List;

my $networks = MogileFS::Network::List->new();

ok($networks->add_network('127.0.0.0/16', 'one'), 'Add zone one');
ok($networks->add_network('127.0.0.0/25', 'two'), 'Add zone two');
ok($networks->add_network('127.0.0.128/25', 'three'), 'Add zone three');
is($networks->match_most_specific_zone('127.0.0.1'), 'two', 'Most specific match against zone two');
is($networks->match_most_specific_zone('127.0.0.140'), 'three', 'Most specific match against zone three');
is($networks->match_most_specific_zone('172.16.0.1'), undef, 'Unknown zone for most specific network');
is($networks->matching_zones('172.16.0.1'), 0, 'Unknown zone for any matching networks');

my @zones = $networks->matching_zones('127.0.0.1');
my @expected_zones = qw(two one);
is_deeply(\@zones, \@expected_zones, 'Multiple zones returned when IP resides in multiple zone networks');
