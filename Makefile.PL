#!/usr/bin/perl

use strict;
use warnings;
our $VERSION = 0.011_000;

use ExtUtils::MakeMaker;
use Alien::Build::MM;

BEGIN { 
    use Config;
    use English qw(-no_match_vars);  # for $OSNAME
    use Data::Dumper;  # DEBUG

    # remove previous Alien build directory, ensure only one build process to be found by t/02_make_check.t
    use File::Path qw(remove_tree);
    my $removed_count = remove_tree('_alien');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, after calling remove_tree('_alien'), have $removed_count = }, $removed_count, "\n\n";

    # install Alien::PCRE2 if not already present, must be done here rather than in CONFIGURE_REQUIRES section below or "configure requires" section of alienfile,
    # otherwise Alien::PCRE2 will not be installed early enough to be used in the alienfile itself
    my $eval_retval = eval 'use Alien::PCRE2; 1;';
    if (not defined $eval_retval) {  # runtime error occurred, Alien::PCRE2 presumably not installed
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, after calling eval 'use Alien::PCRE2; 1;', have $EVAL_ERROR = '}, $EVAL_ERROR, q{'}, "\n\n";

=begin DISABLED_CPAN

        $eval_retval = eval 'use CPAN; 1;';
        if (not defined $eval_retval) {  # runtime error occurred, CPAN presumably not installed
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, after calling eval 'use CPAN; 1;', have $EVAL_ERROR = '}, $EVAL_ERROR, q{'}, "\n\n";
            die 'ERROR EAP00: Alien::PCRE2 and CPAN distributions are not installed, can not automatically install Alien::PCRE2 for use in alienfile, please manually install Alien::PCRE2, dying';
        }

=end DISABLED_CPAN

=cut

        use Cwd;
        my $pre_cpan_dir = getcwd();
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, have $pre_cpan_dir = '}, $pre_cpan_dir, q{'}, "\n\n";

        # use cpanm to install Alien::PCRE2
        use IPC::Cmd qw(can_run);
        my $cpanm_path = can_run('cpanm');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, have $cpanm_path = '}, $cpanm_path, q{'}, "\n\n";
        if ((not defined $cpanm_path) or ($cpanm_path eq q{})) {
            die 'ERROR EAJ00: Alien::PCRE2 and cpanm are not installed, can not automatically install Alien::PCRE2 for use in alienfile, please manually install Alien::PCRE2, dying';
        }

        use Capture::Tiny qw( capture_merged );
        # run `cpanm Alien::PCRE2`, check for valid output
        my $cpanm_output = [ split /\r?\n/, capture_merged { system $cpanm_path . ' Alien::PCRE2'; }];
        print {*STDERR} "\n\n", '<<< DEBUG >>> in Makefile.PL, have $cpanm_output =', Dumper($cpanm_output), "\n\n";
        my $cpanm_output_success = 0;
        foreach my $cpanm_output_line (@{$cpanm_output}) {
            if ($cpanm_output_line =~ m/^Successfully installed Alien-PCRE2/xms) {
                $cpanm_output_success = 1;
                last;
            }
        }
        if (not $cpanm_output_success) {
            die 'ERROR EAJ01: `cpanm Alien::PCRE2` did not successfully install, can not automatically install Alien::PCRE2 for use in alienfile, please manually install Alien::PCRE2, dying';
        }

=begin DISABLED_CPAN

        # DISABLED: use cpan to install Alien::PCRE2, keeps getting stuck at interactive configuration
        use CPAN;
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, about to call CPAN o conf defaults...}, "\n\n";
        CPAN::Shell->o('conf', 'defaults');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, about to call CPAN o conf commit...}, "\n\n";
        CPAN::Shell->o('conf', 'commit');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, about to call CPAN to install Alien::PCRE2...}, "\n\n";
        CPAN::Shell->install('Alien::PCRE2');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, returned from call CPAN to install Alien::PCRE2}, "\n\n";

=end DISABLED

=cut

        my $post_cpan_dir = getcwd();
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, have $post_cpan_dir = '}, $post_cpan_dir, q{'}, "\n\n";
        chdir $pre_cpan_dir;
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, after chdir, have getcwd() = '}, getcwd(), q{'}, "\n\n";


    }
}

# fix read-only blib/lib in MS Windows
if ( $OSNAME eq 'MSWin32' ) {
    push( @ExtUtils::MakeMaker::Overridable, qw(pm_to_blib) );
}

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME         => 'Alien::JPCRE2',
    DISTNAME     => 'Alien-JPCRE2',
    ABSTRACT     => 'Find Or Download/Build/Install libjpcre2 In JPCRE2',
    VERSION_FROM => 'lib/Alien/JPCRE2.pm',
    AUTHOR           => 'Will Braswell <wbraswell@cpan.org>',
    LICENSE          => 'perl_5',
#    EXE_FILES        => ['bin/foo'],  # error, no rule to make target 'bin/foo'
#    MAKE             => 'gmake',

    CONFIGURE_REQUIRES => {
        # DEV NOTE, CORRELATION #ap001: must install IO::Socket::SSL & Alien::Build from Makefile.PL (which becomes META.json, for CPAN) & .travis.yml & appveyor.yml 
        'IO::Socket::SSL'       => '2.043',
        'Alien::Build'          => '0.52',  # provides Alien::Build::MM
#        'Alien::PCRE2'          => '0.006',  NEED REMOVE: moved to alienfile
        'CPAN'                  => '2'
    },

    META_MERGE => {
        'meta-spec' => {
            version => '2',
            url     => 'https://metacpan.org/pod/CPAN::Meta::Spec'
        },

        release_status => 'stable',
        keywords       => [qw(alien pcre pcre2 jpcre2 regex regularexpression)],
        description    => 'JPCRE2 is the C++ wrapper for the new Perl Compatible Regular Expression engine, written in C, compiled and installed via Alien',
        resources => {
            license    => ['http://dev.perl.org/licenses/'],
            homepage   => 'https://neurobin.org/projects/softwares/libs/jpcre2/',
            bugtracker => { web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Alien-JPCRE2' },
            repository => {
                type => 'git',
                url  => 'git://github.com/wbraswell/alien-jpcre2.git',
                web  => 'https://github.com/wbraswell/alien-jpcre2',
            },
            x_IRC         => "irc://irc.perl.org/#native",
#            x_mailinglist => "https://NONE",
#            x_wiki        => "https://NONE",
        },
    },
));


package MY;
BEGIN { use English; }

sub postamble {
    $abmm->mm_postamble;
}

sub pm_to_blib {
    my $self = shift;
    my $blib = $self->SUPER::pm_to_blib(@_);

    # un-read-only blib/lib for tests to pass, files are modified at runtime there
    if ( $OSNAME eq 'MSWin32' ) {
        my ( $lastline, $start ) = qq{\t\$(NOECHO) \$(TOUCH) pm_to_blib\n};
        ( $start = index( $blib, $lastline ) ) == -1
            && die "Can't find replacement string for pm_to_blib target";
        substr( $blib, $start, 0, "\t" . 'attrib -R /S  blib/lib/*' . "\n" );
    }
    return $blib;
}
