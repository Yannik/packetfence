package pf::k8s::deployments;

=head1 NAME

pf::k8s::deployments

=cut

=head1 DESCRIPTION

Module to manage access to the deployments API of a K8S control plane

=cut


use pf::constants qw($TRUE);
use HTTP::Request::Common;

use Moo;
extends "pf::k8s";

sub list {
    my ($self, $params) = @_;
    return $self->execute_request(HTTP::Request::Common::GET($self->build_uri("/apis/apps/v1/namespaces/".$self->namespace."/deployments", $params)));
}

sub get {
    my ($self, $deployment, $params) = @_;
    return $self->execute_request(HTTP::Request::Common::GET($self->build_uri("/apis/apps/v1/namespaces/".$self->namespace."/deployment/".$deployment, $params)));
}

sub rollout_restart {

}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2022 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;

