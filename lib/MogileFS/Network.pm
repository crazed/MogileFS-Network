package MogileFS::Network;

=head1 NAME

MogileFS::Network - Network awareness and extensions for MogileFS::Server

=head1 DESCRIPTION

This collection of modules adds multiple network awareness to the MogileFS
server. It provides two replication policies, 'MultipleNetworks' and
'HostsPerNetwork'; and also provides a plugin 'ZoneLocal' that causes
get_paths queries to be returned in a prioritized order based on locality of
storage.

For information on configuring a location-aware installation of MogileFS
please check out the MogileFS wiki.

L<http://code.google.com/p/mogilefs/wiki/ConfigureMultiNet>

=cut

use strict;
use warnings;

use Net::Netmask;
use MogileFS::Config;
use MogileFS::Network::List;

our $VERSION = "0.06";

use constant DEFAULT_RELOAD_INTERVAL => 60;

my $networks = MogileFS::Network::List->new(); # objected used for cache and lookup
my $next_reload = 0;                           # Epoch time at or after which the trie expires and must be regenerated.
my $has_cached = MogileFS::Config->can('server_setting_cached');

sub zone_for_ip {
    my $class = shift;
    my $ip = shift;

    return unless $ip;

    check_cache();

    return $networks->match_most_specific_zone($ip);
}

sub zones_for_ip {
    my $class = shift;
    my $ip = shift;
    return unless $ip;

    check_cache();

    return $networks->matching_zones($ip);
}

sub check_cache {
    # Reload the trie if it's expired
    return unless (time() >= $next_reload);

    $networks = MogileFS::Network::List->new();

    my @zones = split(/\s*,\s*/, get_setting("network_zones"));

    my @netmasks; # [ $bits, $netmask, $zone ], ...

    foreach my $zone (@zones) {
        my $zone_masks = get_setting("zone_$zone");

        if (not $zone_masks) {
            warn "couldn't find network_zone <<zone_$zone>> check your server settings";
            next;
        }

        foreach my $network_string (split /[,\s]+/, $zone_masks) {
            my $netmask = Net::Netmask->new2($network_string);

            if (Net::Netmask::errstr()) {
                warn "couldn't parse <$zone> as a netmask. error was <" . Net::Netmask::errstr().
                     ">. check your server settings";
                next;
            }

            push @netmasks, [$netmask->bits, $netmask, $zone];
        }
    }

    foreach my $set (@netmasks) {
        my ($bits, $netmask, $zone) = @$set;
        $networks->add_network("$netmask", $zone);
    }

    my $interval = get_setting("network_reload_interval") || DEFAULT_RELOAD_INTERVAL;

    $next_reload = time() + $interval;

    return 1;
}

# This is a separate subroutine so I can redefine it at test time.
sub get_setting {
    my $key = shift;
    if ($has_cached) {
        my $val = MogileFS::Config->server_setting_cached($key);
        return $val;
    }
    # Fall through to the server in case we don't have a cached value yet.
    return MogileFS::Config->server_setting($key);
}

sub test_config {
    my $class = shift;

    my %config = @_;

    no warnings 'redefine';

    *get_setting = sub {
        my $key = shift;
        return $config{$key};
    };

    $next_reload = 0;
}

=head1 COPYRIGHT

Copyright 2011 - Jonathan Steinert

=head1 AUTHOR

Jonathan Steinert

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=cut

1;
