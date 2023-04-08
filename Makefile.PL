use v5.10;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'azu',
    VERSION_FROM  => 'bin/azu',
    ABSTRACT_FROM => 'bin/azu.pod',
    EXE_FILES     => [ 'bin/azu' ],
    PREREQ_PM     => { },
    AUTHOR        => 'Juerd Waalboer <juerd@cpan.org>',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Juerd/azu.git',
                web  => 'https://github.com/Juerd/azu',
            },
            bugtracker => {
                web => 'https://github.com/Juerd/azu/issues'
            },
        },
    },
);
