package pfappserver::Form::Config::Pfcron;

=head1 NAME

pfappserver::Form::Config::Pfcron - Web form for maintenance.conf

=head1 DESCRIPTION

Form definition to update an pfcron tasks

=cut

use strict;
use warnings;
use HTML::FormHandler::Moose;
extends 'pfappserver::Base::Form';
with 'pfappserver::Base::Form::Role::Help';
use pf::config::pfcron qw(%ConfigCronDefault);

use Exporter qw(import);
our @EXPORT_OK = qw(default_field_method batch_help_text timeout_help_text window_help_text);
use pf::log;

## Definition
has_field 'id' =>
  (
   type => 'Text',
   label => 'Pfcron Name',
   required => 1,
   messages => { required => 'Please specify the name of the maintenance task' },
  );

has_field 'description' =>
  (
   type => 'Text',
   inactive => 1,
  );

has_field 'type' =>
  (
   type => 'Hidden',
   required => 1,
  );

has_field 'status' =>
  (
   type => 'Toggle',
   checkbox_value => 'enabled',
   unchecked_value => 'disabled',
   default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => 'Whether or not this task is enabled.<br>Requires a restart of pfcron to be effective.' },
  );

has_field 'schedule' =>
  (
   type => 'Text',
   default_method => \&default_field_method,
    tags => { after_element => \&help,
             help => 'The schedule for maintenance task (cron like spec).' },
  );

has_block  definition =>
  (
    render_list => [qw(type status schedule)],
  );

my $desc_rx = qr/(@(?:annually|yearly|monthly|weekly|daily|hourly))|(\@every (?:\d+(?:ns|us|µs|ms|s|m|h))+)/;
my $single_spec = qr/^(?:(?:\d+(-\d+)?(\/\d+)?))|((\/\d+))$/;
my $monthly_spec = qr/^
    (?:(?:\d+|(?i:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec))(-(\d+|(?i:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)))?(\/\d+))?|
    (\/\d+)
$/x;

my $dow_spec = qr/^
    (?:(?:\d+|(?i:sun|mon|tue|wed|thu|fri|sat))(-(\d+|(?i:sun|mon|tue|wed|thu|fri|sat)))?(\/\d+))?|
    (\/\d+)
$/x;

sub default_field_method {
    my ($field) = @_;
    my $name = $field->name;
    my $task_name = ref($field->form);
    $task_name =~ s/^pfappserver::Form::Config::Pfcron:://;
    my $value = $ConfigCronDefault{$task_name}{$name};
    if ($field->has_inflate_default_method) {
        $value = $field->inflate_default($value);
    }

    return $value;
}

sub validate_schedule {
    my ($form, $field) = @_;
    my $schedule = $field->value;
    if (!check_cron_spec($schedule)) {
        $field->add_error("Cron spec is invalid");
    }
}

sub check_cron_spec {
    my ($spec) = @_;
    if ($spec =~ $desc_rx) {
        return 1;
    }

    my @parts = split /\s+/, $spec;
    if (@parts < 5 || @parts > 6) {
        return 0;
    }

    for my $p (@parts[0 .. ($#parts - 2)]) {
        if (!check_cron_spec_part($p, $single_spec)) {
            return 0;
        }
    }

    if (!check_cron_spec_part($parts[-2], $monthly_spec)) {
        return 0;
    }

    if (!check_cron_spec_part($parts[-1], $dow_spec)) {
        return 0;
    }

    return 1;
}

sub check_cron_spec_part {
    my ($part, $rx) = @_;
    if ($part eq '*' || $part eq '?') {
       return 1;
    }

    return all {$_ =~ $rx} split (',', $part);
}

sub batch_help_text { "Amount of items that will be processed in each batch of this task. Batches are executed until there is no more items to process or until the timeout is reached." }

sub timeout_help_text { "Maximum amount of time this task can run." }

sub window_help_text { "Window to apply the job to. In the case of a deletion, setting this to 7 days would delete affected data older than 7 days." }

=head1 COPYRIGHT

Copyright (C) 2005-2023 Inverse inc.

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

__PACKAGE__->meta->make_immutable unless $ENV{"PF_SKIP_MAKE_IMMUTABLE"};
1;
