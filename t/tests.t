#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Differences qw(eq_or_diff);
use IPC::Open2;
use autodie;

# The example zone file is based on DNS-ZoneParse-1.10/source/t/test-zone.db

sub azu {
	my $pid = open2(my $out, my $in, 'bin/azu', '--origin' => 'origin', @_);
	print $in <<'END';
@  IN  SOA     ns0.dns-zoneparse-test.net.     support\.contact.dns-zoneparse-test.net.        (
                        2000100502   ; serial number
                        10801       ; refresh
                        3600        ; retry
                        691200      ; expire
                        86400     ) ; minimum TTL
 
         43200          IN      NS      ns0.dns-zoneparse-test.net.
@                       IN      NS      ns1.dns-zoneparse-test.net.
 
@                       IN      A       127.0.0.1
@                       IN      MX      10      mail
ftp                     IN      CNAME   www
localhost               IN      A       127.0.0.1
mail                    IN      A       127.0.0.1
www                     IN      A       127.0.0.1
                        in      a       10.0.0.2
www      43200          IN      A       10.0.0.3
foo                     IN      A       10.0.0.6
mini                            A       10.0.0.7
icarus                  IN      AAAA    fe80::0260:83ff:fe7c:3a2a

$ORIGIN subdomain
bla   A 127.0.0.1

$ORIGIN different-absolute-origin.
bla   A 127.0.0.1
txttest1                        TXT     "I've\"got\\back\\\"slashes;!" ; com\\ent
txttest2                        TXT     embedded\"quote ;comment
txttest3                        TXT     noquotes;comment
txttest4                        TXT     "MORE (complicated) stuff -h343-"
END
	close $in;
	local $/;
	return readline $out;
}



eq_or_diff(azu('--after-every' => '* A', '--add' => 'HERE', '--raw'), <<'END', '* does not match origin itself');
@  IN  SOA     ns0.dns-zoneparse-test.net.     support\.contact.dns-zoneparse-test.net.        (
                        2000100502   ; serial number
                        10801       ; refresh
                        3600        ; retry
                        691200      ; expire
                        86400     ) ; minimum TTL
 
         43200          IN      NS      ns0.dns-zoneparse-test.net.
@                       IN      NS      ns1.dns-zoneparse-test.net.
 
@                       IN      A       127.0.0.1
@                       IN      MX      10      mail
ftp                     IN      CNAME   www
localhost               IN      A       127.0.0.1
HERE
mail                    IN      A       127.0.0.1
HERE
www                     IN      A       127.0.0.1
HERE
                        in      a       10.0.0.2
HERE
www      43200          IN      A       10.0.0.3
HERE
foo                     IN      A       10.0.0.6
HERE
mini                            A       10.0.0.7
HERE
icarus                  IN      AAAA    fe80::0260:83ff:fe7c:3a2a

$ORIGIN subdomain
bla   A 127.0.0.1
HERE

$ORIGIN different-absolute-origin.
bla   A 127.0.0.1
txttest1                        TXT     "I've\"got\\back\\\"slashes;!" ; com\\ent
txttest2                        TXT     embedded\"quote ;comment
txttest3                        TXT     noquotes;comment
txttest4                        TXT     "MORE (complicated) stuff -h343-"
END



eq_or_diff(azu('--after-every' => '*. A', '--add' => 'HERE', '--raw'), <<'END', '*. matches everywhere');
@  IN  SOA     ns0.dns-zoneparse-test.net.     support\.contact.dns-zoneparse-test.net.        (
                        2000100502   ; serial number
                        10801       ; refresh
                        3600        ; retry
                        691200      ; expire
                        86400     ) ; minimum TTL
 
         43200          IN      NS      ns0.dns-zoneparse-test.net.
@                       IN      NS      ns1.dns-zoneparse-test.net.
 
@                       IN      A       127.0.0.1
HERE
@                       IN      MX      10      mail
ftp                     IN      CNAME   www
localhost               IN      A       127.0.0.1
HERE
mail                    IN      A       127.0.0.1
HERE
www                     IN      A       127.0.0.1
HERE
                        in      a       10.0.0.2
HERE
www      43200          IN      A       10.0.0.3
HERE
foo                     IN      A       10.0.0.6
HERE
mini                            A       10.0.0.7
HERE
icarus                  IN      AAAA    fe80::0260:83ff:fe7c:3a2a

$ORIGIN subdomain
bla   A 127.0.0.1
HERE

$ORIGIN different-absolute-origin.
bla   A 127.0.0.1
HERE
txttest1                        TXT     "I've\"got\\back\\\"slashes;!" ; com\\ent
txttest2                        TXT     embedded\"quote ;comment
txttest3                        TXT     noquotes;comment
txttest4                        TXT     "MORE (complicated) stuff -h343-"
END



eq_or_diff(azu('--increment'), <<'END', 'increment serial');
@  IN  SOA     ns0.dns-zoneparse-test.net.     support\.contact.dns-zoneparse-test.net.        (
                        2000100503   ; serial number
                        10801       ; refresh
                        3600        ; retry
                        691200      ; expire
                        86400     ) ; minimum TTL
 
         43200          IN      NS      ns0.dns-zoneparse-test.net.
@                       IN      NS      ns1.dns-zoneparse-test.net.
 
@                       IN      A       127.0.0.1
@                       IN      MX      10      mail
ftp                     IN      CNAME   www
localhost               IN      A       127.0.0.1
mail                    IN      A       127.0.0.1
www                     IN      A       127.0.0.1
                        in      a       10.0.0.2
www      43200          IN      A       10.0.0.3
foo                     IN      A       10.0.0.6
mini                            A       10.0.0.7
icarus                  IN      AAAA    fe80::0260:83ff:fe7c:3a2a

$ORIGIN subdomain
bla   A 127.0.0.1

$ORIGIN different-absolute-origin.
bla   A 127.0.0.1
txttest1                        TXT     "I've\"got\\back\\\"slashes;!" ; com\\ent
txttest2                        TXT     embedded\"quote ;comment
txttest3                        TXT     noquotes;comment
txttest4                        TXT     "MORE (complicated) stuff -h343-"
END



eq_or_diff(azu('--replace-every' => '*. NS', '--with' => '% NS replaced'), <<'END', 'replace and reuse name');
@  IN  SOA     ns0.dns-zoneparse-test.net.     support\.contact.dns-zoneparse-test.net.        (
                        2000100502   ; serial number
                        10801       ; refresh
                        3600        ; retry
                        691200      ; expire
                        86400     ) ; minimum TTL
 
;         43200          IN      NS      ns0.dns-zoneparse-test.net.
origin.	43200	IN	NS	replaced.origin.
;@                       IN      NS      ns1.dns-zoneparse-test.net.
origin.	IN	NS	replaced.origin.
 
@                       IN      A       127.0.0.1
@                       IN      MX      10      mail
ftp                     IN      CNAME   www
localhost               IN      A       127.0.0.1
mail                    IN      A       127.0.0.1
www                     IN      A       127.0.0.1
                        in      a       10.0.0.2
www      43200          IN      A       10.0.0.3
foo                     IN      A       10.0.0.6
mini                            A       10.0.0.7
icarus                  IN      AAAA    fe80::0260:83ff:fe7c:3a2a

$ORIGIN subdomain
bla   A 127.0.0.1

$ORIGIN different-absolute-origin.
bla   A 127.0.0.1
txttest1                        TXT     "I've\"got\\back\\\"slashes;!" ; com\\ent
txttest2                        TXT     embedded\"quote ;comment
txttest3                        TXT     noquotes;comment
txttest4                        TXT     "MORE (complicated) stuff -h343-"
END



eq_or_diff(azu('--before-every' => '*. A 127.1', '--add' => '% A ::1', '--raw'), <<'END', 'ipv6 yay');
@  IN  SOA     ns0.dns-zoneparse-test.net.     support\.contact.dns-zoneparse-test.net.        (
                        2000100502   ; serial number
                        10801       ; refresh
                        3600        ; retry
                        691200      ; expire
                        86400     ) ; minimum TTL
 
         43200          IN      NS      ns0.dns-zoneparse-test.net.
@                       IN      NS      ns1.dns-zoneparse-test.net.
 
@ A ::1
@                       IN      A       127.0.0.1
@                       IN      MX      10      mail
ftp                     IN      CNAME   www
localhost A ::1
localhost               IN      A       127.0.0.1
mail A ::1
mail                    IN      A       127.0.0.1
www A ::1
www                     IN      A       127.0.0.1
                        in      a       10.0.0.2
www      43200          IN      A       10.0.0.3
foo                     IN      A       10.0.0.6
mini                            A       10.0.0.7
icarus                  IN      AAAA    fe80::0260:83ff:fe7c:3a2a

$ORIGIN subdomain
bla A ::1
bla   A 127.0.0.1

$ORIGIN different-absolute-origin.
bla A ::1
bla   A 127.0.0.1
txttest1                        TXT     "I've\"got\\back\\\"slashes;!" ; com\\ent
txttest2                        TXT     embedded\"quote ;comment
txttest3                        TXT     noquotes;comment
txttest4                        TXT     "MORE (complicated) stuff -h343-"
END



eq_or_diff(azu('--match' => 'icarus A', '--add' => 'HERE', '--raw', '--if-match-count' => 0), <<'END', 'only if none found: positive');
@  IN  SOA     ns0.dns-zoneparse-test.net.     support\.contact.dns-zoneparse-test.net.        (
                        2000100502   ; serial number
                        10801       ; refresh
                        3600        ; retry
                        691200      ; expire
                        86400     ) ; minimum TTL
 
         43200          IN      NS      ns0.dns-zoneparse-test.net.
@                       IN      NS      ns1.dns-zoneparse-test.net.
 
@                       IN      A       127.0.0.1
@                       IN      MX      10      mail
ftp                     IN      CNAME   www
localhost               IN      A       127.0.0.1
mail                    IN      A       127.0.0.1
www                     IN      A       127.0.0.1
                        in      a       10.0.0.2
www      43200          IN      A       10.0.0.3
foo                     IN      A       10.0.0.6
mini                            A       10.0.0.7
icarus                  IN      AAAA    fe80::0260:83ff:fe7c:3a2a

$ORIGIN subdomain
bla   A 127.0.0.1

$ORIGIN different-absolute-origin.
bla   A 127.0.0.1
txttest1                        TXT     "I've\"got\\back\\\"slashes;!" ; com\\ent
txttest2                        TXT     embedded\"quote ;comment
txttest3                        TXT     noquotes;comment
txttest4                        TXT     "MORE (complicated) stuff -h343-"
HERE
END



eq_or_diff(azu('--match' => 'icarus AAAA', '--add' => 'HERE', '--raw', '--if-match-count' => 0), <<'END', 'only if none found: negative');
@  IN  SOA     ns0.dns-zoneparse-test.net.     support\.contact.dns-zoneparse-test.net.        (
                        2000100502   ; serial number
                        10801       ; refresh
                        3600        ; retry
                        691200      ; expire
                        86400     ) ; minimum TTL
 
         43200          IN      NS      ns0.dns-zoneparse-test.net.
@                       IN      NS      ns1.dns-zoneparse-test.net.
 
@                       IN      A       127.0.0.1
@                       IN      MX      10      mail
ftp                     IN      CNAME   www
localhost               IN      A       127.0.0.1
mail                    IN      A       127.0.0.1
www                     IN      A       127.0.0.1
                        in      a       10.0.0.2
www      43200          IN      A       10.0.0.3
foo                     IN      A       10.0.0.6
mini                            A       10.0.0.7
icarus                  IN      AAAA    fe80::0260:83ff:fe7c:3a2a

$ORIGIN subdomain
bla   A 127.0.0.1

$ORIGIN different-absolute-origin.
bla   A 127.0.0.1
txttest1                        TXT     "I've\"got\\back\\\"slashes;!" ; com\\ent
txttest2                        TXT     embedded\"quote ;comment
txttest3                        TXT     noquotes;comment
txttest4                        TXT     "MORE (complicated) stuff -h343-"
END



done_testing;
