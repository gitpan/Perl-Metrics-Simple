# $Header: /usr/local/CVS/Perl-Metrics-Simple/t/more_test_files/main_subs_and_pod.pl,v 1.1 2008/03/15 18:07:51 matisse Exp $
# $Revision: 1.1 $
# $Author: matisse $
# $Source: /usr/local/CVS/Perl-Metrics-Simple/t/more_test_files/main_subs_and_pod.pl,v $
# $Date: 2008/03/15 18:07:51 $

package main_subs_and_pod; # 1

use strict; # 2
use warnings; # 3

our $VERSION = '1.0'; # 4

our $EXPECTED_NON_SUB_LINES = 8; #5

exit run(@ARGV) if not caller(); # 6

sub run {
    my @args = @_;
    say( @args );
    return 1;
}

sub say {
    my @args = @_;
    print "@args";
}

1;   # 7 This line is in "main" and so counts as a non-subroutine line.

# the __END__ token also counts as a line of code.s
__END__

bad_line of code

=pod

=head1 NAME

Fake::Package::For::Testing

=head1 DESCRIPTION

Used to test counts of lines not in any subroutine. That count should NOT
includes comments and pod.

=cut