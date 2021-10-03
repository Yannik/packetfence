#!/usr/bin/perl

=head1 NAME

IPAddress

=head1 DESCRIPTION

unit test for IPAddress

=cut

use strict;
use warnings;

our @OptionsTests;
BEGIN {
    #include test libs
    use lib qw(/usr/local/pf/t);
    #Module for overriding configuration paths
    use setup_test_config;

    @OptionsTests = (
        {
            new => [ name => 'int' ],
            out => {
                    default     => undef,
                    implied     => undef,
                    placeholder => undef,
                    min_value   => 0,
                    required => 0,
                    type => "integer",
            },
            msg => 'Message options max_value = 10',
        },
        {
            new => [ name => 'int', range_end => 10],
            out => {
                    default     => undef,
                    implied     => undef,
                    placeholder => undef,
                    min_value   => 0,
                    max_value   => 10,
                    required => 0,
                    type => "integer",
            },
            msg => 'Message options max_value = 10',
        },
    );
}

{
    package validInt;
    use pf::validator::Moose;
    extends qw(pf::validator);
    has_field int => (
        type     => 'PosInteger',
    );
}

use Test::More tests => 6 + scalar @OptionsTests;

#This test will running last
use Test::NoWarnings;


{
    my $v = validInt->new();
    my $ctx = pf::validator::Ctx->new;
    $v->validate($ctx, { int => "1" });
    my $errors = $ctx->errors;
    is_deeply ($errors, [], "Valid Integer");

    $ctx->reset();
    $v->validate($ctx, { int => "-1" });
    $errors = $ctx->errors;
    is_deeply ($errors, [{ field => 'int', message => 'must be a Postive Integer' }], "Valid Integer");

    $ctx->reset();
    $v->validate($ctx, { int => "-10" });
    $errors = $ctx->errors;
    is_deeply ($errors, [{ field => 'int', message => 'must be a Postive Integer' }], "Valid Integer");

    $ctx->reset();
    $v->validate($ctx, { int => "+10" });
    $errors = $ctx->errors;
    is_deeply ($errors, [], "Valid Integer");

    $ctx->reset();
    $v->validate($ctx, { int => "asas" });
    $errors = $ctx->errors;
    is_deeply ($errors, [{ field => 'int', message => 'must be a Postive Integer' }], "Has errors int");
}
#Options test
{
    for my $t ( @OptionsTests ) {
        my $f = pf::validator::Field::PosInteger->new(@{$t->{new}});
        is_deeply (
            $f->optionsMeta(),
            $t->{out},
            $t->{msg}
        );
    }
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2021 Inverse inc.

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

