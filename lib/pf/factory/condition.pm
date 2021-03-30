package pf::factory::condition;

=head1 NAME

pf::factory::condition -

=head1 DESCRIPTION

pf::factory::condition

=cut

use strict;
use warnings;
use pf::constants::condition_parser qw($TRUE_CONDITION);
use Module::Pluggable
  search_path => 'pf::condition',
  sub_name    => '_modules',
  inner       => 0,
  require     => 1;

our @MODULES;

__PACKAGE__->modules;

sub modules {
    my ($class) = @_;
    unless(@MODULES) {
        @MODULES = $class->_modules;
    }
    return @MODULES;
}

our %LOGICAL_OPS = (
    AND => 'pf::condition::all',
    OR  => 'pf::condition::any'
);

our %BINARY_OP = (
    "==" => 'pf::condition::equals',
    "!=" => 'pf::condition::not_equals',
    "=~" => 'pf::condition::regex',
    "!~" => 'pf::condition::regex_not',
    ">"  => 'pf::condition::greater',
    ">=" => 'pf::condition::greater_equals',
    "<"  => 'pf::condition::lower',
    "<=" => 'pf::condition::lower_equals',
);

our %FUNC_OPS = (
    'includes'               => 'pf::condition::includes',
    'contains'               => 'pf::condition::matches',
    'not_contains'           => 'pf::condition::not_matches',
    'defined'                => 'pf::condition::is_defined',
    'not_defined'            => 'pf::condition::not_defined',
    'date_is_before'         => 'pf::condition::date_before',
    'date_is_after'          => 'pf::condition::date_after',
    'fingerbank_device_is_a' => 'pf::condition::fingerbank::device_is_a',
    'time_period'            => 'pf::condition::time_period',
    'starts_with'            => 'pf::condition::starts_with',
    'ends_with'              => 'pf::condition::ends_with',
    'true'                   => 'pf::condition::true',
);

our %NO_KEY = (
    'time_period' => 1,
);

=head2 buildCondition

build a condition

=cut

sub buildCondition {
    my ($ast) = @_;
    if (ref $ast) {
        local $_;
        my ($op, @rest) = @$ast;
        if ($op eq 'NOT' ) {
            return pf::condition::not->new(
                {
                    condition => buildCondition(@rest)
                }
            );
        }

        if (exists $LOGICAL_OPS{$op}) {
            if (@rest == 1) {
                return buildCondition( @rest);
            }

            return $LOGICAL_OPS{$op}->new({conditions => [map { buildCondition($_) } @rest]});
        }

        if (exists $BINARY_OP{$op}) {
            my ($key, $val) = @rest;
            my $sub_condition = $BINARY_OP{$op}->new(value => $val);
            return build_parent_condition($sub_condition, $key);
        }

        if ($op eq 'FUNC') {
            my ($func, $params) = @rest;
            my $wrap_in_not;
            if (!exists $FUNC_OPS{$func}) {
                die "op '$func' not handled" unless ($func =~ s/^not_//);
                die "op 'not_$func' not handled" unless exists $FUNC_OPS{$func};
                $wrap_in_not = 1;
            }

            if ($func eq $TRUE_CONDITION) {
                return pf::condition::true->new();
            }

            my ($key, $val) = @$params;
            my $sub_condition = $FUNC_OPS{$func}->new(value => $val);
            my $condition;
            if (exists $NO_KEY{$func}) {
                $condition = $sub_condition;
            } else {
                $condition = build_parent_condition($sub_condition, $key);
            }

            return $wrap_in_not ? pf::condition::not->new({condition => $condition}) : $condition;
        }

        die "op '$op' not handled";
    }

    if ($ast eq $TRUE_CONDITION) {
        return pf::condition::true->new;
    }

    die "condition '$ast' not defined\n";
}

sub build_parent_condition {
    my ($child, $key) = @_;
    my @parents = split /\./, $key;
    if (@parents == 1) {
        return pf::condition::key->new({
            key       => $key,
            condition => $child,
        });
    }

    return _build_parent_condition($child, @parents);
}

sub _build_parent_condition {
    my ($child, $key, @parents) = @_;
    if (@parents == 0) {
        return pf::condition::key->new({
            key       => $key,
            condition => $child,
        });
    }

    return pf::condition::key->new({
        key       => $key,
        condition => _build_parent_condition($child, @parents),
    });
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2020 Inverse inc.

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

