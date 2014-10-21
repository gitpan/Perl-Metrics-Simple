# $Header: /usr/local/CVS/Perl-Metrics-Simple/t/0030_analyze.t,v 1.12 2006/11/23 22:25:48 matisse Exp $
# $Revision: 1.12 $
# $Author: matisse $
# $Source: /usr/local/CVS/Perl-Metrics-Simple/t/0030_analyze.t,v $
# $Date: 2006/11/23 22:25:48 $
###############################################################################

use strict;
use warnings;
use English qw(-no_match_vars);
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Perl::Metrics::Simple::TestData;
use Readonly;
use Test::More tests => 23;

Readonly::Scalar my $TEST_DIRECTORY => "$Bin/test_files";
Readonly::Scalar my $EMPTY_STRING   => q{};

BEGIN {
    use_ok('Perl::Metrics::Simple')
      || BAIL_OUT('Could not compile Perl::Metrics::Simple');
    use_ok('Perl::Metrics::Simple::Analysis::File')
      || BAIL_OUT('Could not compile Perl::Metrics::Simple::Analysis::File');
}

test_analyze_one_file();
test_analyze_files();
test_analysis();

exit;

sub set_up {
    my $test_data_object =
      Perl::Metrics::Simple::TestData->new( test_directory => $TEST_DIRECTORY );
    return $test_data_object;
}

sub test_analyze_one_file {
    my $test_data_object = set_up();
    my $test_data = $test_data_object->get_test_data;
    my $no_package_no_sub_expected_result =
      $test_data->{'no_packages_nor_subs'};
    my $analysis =
      Perl::Metrics::Simple::Analysis::File->new(
        path => $no_package_no_sub_expected_result->{'path'} );
    is_deeply( $analysis->packages, [], 'Analysis of file with no packages.' );
    is_deeply( $analysis->subs,     [], 'Analysis of file with no subs.' );

    my $has_package_no_subs_expected_result =
      $test_data->{'package_no_subs.pl'};
    my $new_analysis =
      Perl::Metrics::Simple::Analysis::File->new(
        path => $has_package_no_subs_expected_result->{'path'} );
    is_deeply(
        $new_analysis->packages,
        $has_package_no_subs_expected_result->{packages},
        'Analysis of file with one package.'
    );
    is_deeply( $new_analysis->subs, [],
        'Analysis of file with one package and no subs.' );

    my $has_subs_expected_result = $test_data->{'subs_no_package.pl'};
    my $has_subs_analysis        =
      Perl::Metrics::Simple::Analysis::File->new(
        path => $has_subs_expected_result->{'path'} );
    is_deeply( $has_subs_analysis->all_counts,
        $has_subs_expected_result, 'analyze_one_file() subs_no_package.pl' );

    my $has_subs_and_package_expected_result = $test_data->{'Module.pm'};
    my $subs_and_package_analysis            =
      Perl::Metrics::Simple::Analysis::File->new(
        path => $has_subs_and_package_expected_result->{'path'} );
    is_deeply(
        $subs_and_package_analysis->all_counts,
        $has_subs_and_package_expected_result,
        'analyze_one_file() with packages and subs.'
    );
}

sub test_analyze_files {
    my $test_data_object     = set_up();
    my $test_data            = $test_data_object->get_test_data;
    my $analyzer             = Perl::Metrics::Simple->new();
    my $analysis_of_one_file =
      $analyzer->analyze_files( $test_data->{'Module.pm'}->{path} );
    isa_ok( $analysis_of_one_file, 'Perl::Metrics::Simple::Analysis' );
    my $expected_from_one_file = $test_data->{'Module.pm'};
    is( scalar @{ $analysis_of_one_file->data }, 1, 'Analysis has only 1 element.');
    isa_ok( $analysis_of_one_file->data->[0], 'Perl::Metrics::Simple::Analysis::File');
    is_deeply( $analysis_of_one_file->data->[0]->all_counts, $expected_from_one_file,
        'analyze_files() when given a single file path.' ) || diag Dumper $analysis_of_one_file->data;

    my $analysis = $analyzer->analyze_files($TEST_DIRECTORY);
    my @expected = (
        $test_data->{'Module.pm'},
        $test_data->{'no_packages_nor_subs'},
        $test_data->{'package_no_subs.pl'},
        $test_data->{'subs_no_package.pl'},
    );
    is( scalar @{ $analysis->data }, scalar @expected, 'analayze_files() gets right number of files.');
    for my $i ( scalar @expected ) {
        is_deeply( $analysis->data->[$i], $expected[$i], 'Got expected results for test file.');
    }
}

sub test_analysis {
    my $test_data_object = set_up();
    my $test_data        = $test_data_object->get_test_data;
    my $analyzer         = Perl::Metrics::Simple->new;
    my $analysis         = $analyzer->analyze_files($TEST_DIRECTORY);

    my $expected_lines;
    map { $expected_lines += $test_data->{$_}->{lines} }
      keys %{$test_data};
    is( $analysis->lines, $expected_lines,
        'analysis->lines() returns correct number' );

    my @expected_files = (
        $test_data->{'Module.pm'}->{path},
        $test_data->{'no_packages_nor_subs'}->{path},
        $test_data->{'package_no_subs.pl'}->{path},
        $test_data->{'subs_no_package.pl'}->{path},
    );
    is_deeply( $analysis->files, \@expected_files,
        'analysis->files() contains expected files.' );
    is(
        $analysis->file_count,
        scalar @expected_files,
        'file_count() returns correct number.'
    );

    my @expected_packages = (
        'Perl::Metrics::Simple::Test::Module',
        'Perl::Metrics::Simple::Test::Module::InnerClass',
        'Hello::Dolly',
    );
    is_deeply( $analysis->packages, \@expected_packages,
        'analysis->packages() returns expected list.' );
    is(
        $analysis->package_count,
        scalar @expected_packages,
        'analysis->package_count returns correct number.'
    );

    my @expected_subs = ();
    foreach my $test_file ( sort keys %{$test_data} ) {
        my @subs = @{ $test_data->{$test_file}->{subs} };
        if ( scalar @subs ) {
            push @expected_subs, @subs;
        }
    }

    is_deeply( $analysis->subs, \@expected_subs,
        'analysis->subs() returns expected list.' );

    is(
        $analysis->sub_count,
        scalar @expected_subs,
        'analysis->subs_count returns correct number.'
    );

    my $expected_main_stats = $test_data_object->get_main_stats;
    is_deeply( $analysis->main_stats, $expected_main_stats,
        'analysis->main_stats returns expected data.' );

    my $expected_file_stats = $test_data_object->get_file_stats;
    is_deeply( $analysis->file_stats, $expected_file_stats,
        'analysis->file_stats returns expected data.' );
    return 1;
}

