package MogileFS::Network::List;

=head1 NAME

MogileFS::Network::List - Handle a list of network to zone mappings for MogileFS::Network

=head1 DESCRIPTION

This module is used by MogileFS::Network to provide an easy way to match IP addresses to zones.

=cut

use strict;
use warnings;

use NetAddr::IP;

sub new {
    my $class = shift;
    my $self = { _networks => {} };
    bless $self, $class;
    return $self;
}

sub add_network {
    my $self = shift;
    my $network = shift;
    my $zone = shift;
    if ($self->networks->{$network}) {
        my $other_zone = @{$self->networks->{$network}}[1];
        warn "duplicate netmask <$network> in network zones '$zone' and '$other_zone'. check your server settings"

    }
    $self->networks->{$network} = [NetAddr::IP->new($network), $zone];
    return 1;
}

# Return the closest matching zone name by network mask length
sub match_most_specific_zone {
    my $self = shift;
    my $ip = shift;
    my @networks = $self->matching_networks($ip);
    return $networks[0][1];
}

# Return an array of matching zones for an IP
sub matching_zones {
    my $self = shift;
    my $ip = shift;
    my @networks = $self->matching_networks($ip);
    return map { @$_[1] } @networks;
}

# Return an array of [$network, $zone], ..
sub matching_networks {
    my $self = shift;
    my $ip = NetAddr::IP->new(shift);
    my @matching_networks;
    foreach my $set (values %{$self->networks}) {
        my ($network, $zone) = @$set;
        if ($ip->within($network)) {
            push @matching_networks, $set;
        }
    }
    return sort { @$b[0]->masklen <=> @$a[0]->masklen } @matching_networks;
}

sub networks {
    my $self = shift;
    return $self->{_networks};
}

1;
