package Dist::Zilla::Plugin::OurDist;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;

use Moose;
with (
	'Dist::Zilla::Role::FileMunger',
	'Dist::Zilla::Role::FileFinderUser' => {
		default_finders => [ ':InstallModules', ':ExecFiles' ],
	},
);

has date_format => (is => 'rw', default => sub { '%Y-%m-%d' });

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub munge_file {
    my ($self, $file) = @_;

    my $content = $file->content;

    my $dist = $self->zilla->name;

    my $munged_dist = 0;
    $content =~ s/
                     ^
                     (\s*)           # capture all whitespace before comment

                     (?:our [ ] \$DIST [ ] = [ ] '[^']+'; [ ] )?  # previously produced output
                     (
                         \#\s*DIST     # capture # DIST
                         \b            # and ensure it ends on a word boundary
                         [             # conditionally
                             [:print:]   # all printable characters after DIST
                             \s          # any whitespace including newlines see GH #5
                         ]*              # as many of the above as there are
                     )
                     $                 # until the EOL}xm
                 /
                     "${1}our \$DIST = '$dist'; $2"/emx and $munged_dist++;

    if ($munged_dist) {
        $self->log_debug(['adding $DIST assignment to %s', $file->name]);
        $file->content($content);
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Add a $DIST to your packages (no line insertion)

=for Pod::Coverage .+

=head1 SYNOPSIS

in F<dist.ini>:

 [OurDist]

in your modules/scripts:

 # DIST

or

 our $DIST = 'Some-Dist'; # DIST


=head1 DESCRIPTION

This module is like L<Dist::Zilla::Plugin::PkgDist> except that it looks for
comments C<# DIST> and put the C<$DIST> assignment there instead of adding
another line. The principle is the same as in L<Dist::Zilla::Plugin::OurVersion>
(instead of L<Dist::Zilla::Plugin::PkgVersion>).


=head1 SEE ALSO

L<Dist::Zilla>
