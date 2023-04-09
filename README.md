# NAME

azu - Artisanal Zonefile Updater

# USAGE

    azu
      [--increment]                Increment SOA serial
      [--ymd [--localtime]]        Update YYYYMMDDnn style SOA serial
      [--origin <DOMAIN>]          Use initial origin
      [--add <RECORD>]             Add record to end of zone file
      [--before[-first|-every] <MATCH>
       --add <RECORD>]             Add record before first or every match
      [--after[-first|-every] <MATCH>
       --add <RECORD>]             Add record after first or every match
      [--replace[-first|-every] <MATCH>
       --with <RECORD>             Replace first or every match
       [--delete]]                 Delete instead of comment existing record
      [--or-at-eof]                Add to end of zone file if no match
      [--raw]                      Don't parse and reformat RECORD
      [--stdout]                   Write to stdout, don't change file
      [--diff]                     Show unified diff, don't change file
      [--help]                     Show usage information
      [--]
      <FILENAME>...                Zone file(s)

# EXAMPLES

    # update serial in ALL zone files
    azu --ymd *.zone

    # New IP address
    azu --replace-every '* A 192.0.2.123' --with '% A 192.0.2.42'

    # Yay, we added IPv6
    azu --after-every '* A 192.0.2.123' --add '% AAAA 2001:db8::42'

    # Let's drop IPv4 support
    azu --replace-every '* A' --with ''

    # New server to add to the pool
    azu --before-first  'round-robin AAAA' --or-at-eof --add '% AAAA 2001:db8::42'

    # Remove server from the pool
    azu --replace 'round-robin AAAA 2001:db8::42' --with ''
    azu --replace 'round-robin AAAA 2001:db8::42' --with '' --delete

    # Add an SPF record; if there already is one, replace it
    azu --replace '@ TXT /v=spf1/' --or-at-eof --add '@ TXT "v=spf1; a mx -all"'

    # Add a verification tag
    azu --add '@ TXT "google-site-verification=..."'

    # Update Let's Encrypt challenge
    azu --replace-every '_acme-challenge TXT' --with '_acme-challenge TXT "..."'

Typically, you would use `--increment` or `--ymd` with every invocation, and
the name of the file to update.

Speaking of typical invocations,

    d=example.org
    azu ... $d.zone && git commit -mupdate $d.zone && nsd-control reload $d && nsd-notify $d

# DESCRIPTION

Azu is a simple tool for updating RFC 1035 DNS zone files, that leaves existing
formatting intact. This allows automated changes to otherwise hand-crafted
(hence "artisanal") DNS zones. Because it does not reformat the rest of the
zone file, it works well with `diff` and `git`.

I wrote this tool because every other DNS changing tool that I could find would
either reformat the zone file completely (deleting comments in the process!), or
have extremely limited matching options. Some existing utilities also dive into
`$INCLUDE`, while I find that in practice, I would rather not have any
automated tool touch the include files unless that's explicitly requested.

Azu was inspired by Ansible's `lineinfile`.

## --origin

Sets the _initial origin_ for parsing the zone file. That is the origin which
is used to interpret the zone file until a `$ORIGIN` control entry is encountered,
and that will be used to interpret any record query or new record on the
command line if the zone file does not start with a `$ORIGIN` control entry.

If no `--origin` is given, the initial origin will be derived from the
filename, removing the `.zone`, `.txt`, or `.db` extension if there is one,
assuming that the rest of the filename is a valid domain name and the origin of
the zone file.

Note that when using multiple zone files, `--origin` is not of much help. Using
multiple files in one command only makes sense if the origins can be derived
from the filenames or if the files have $ORIGIN at the top.

## --increment

Increment the serial number in any SOA record that matches the initial origin.

## --ymd

Use 10 digit yyyymmddnn serial numbers per RIPE-203. Implies `--increment`.

Uses UTC for the date, unless `--localtime` is also provided.

Falls back to simple +1 increment if the resulting serial number is invalid (nn
\> 99) or not greater than the old one.

## --add RECORD

Add the given record to the zone file.

The given record is parsed and reformatted unless `--raw` is used; use `%` as
the record name to keep the name that was parsed from the matching record.

If the matching record had an explicit TTL, it is copied over to the new
record unless `--raw` is used.

## --raw

Don't parse and reformat the new record to be added, but just write a line of
text to the zone file. This allows you to keep the artisanal appearance of your
zone file, and to introduce different kinds of syntax errors.

In this case, any explicit TTL from the matched record is not carried over.

## --before\[-first|-every\] MATCH

## --after\[-first|-every\] MATCH

## --replace\[-first|-every\] MATCH

Selects where in the zone file to add the record provided with `--add`.

        <host> [<type> [<rdata|regex>]]

        '@ MX'
        '@ MX 10 mx1.example.org.'
        '@ MX /mx\d/i'

The match is formatted and parsed like a regular record, but the value (rdata)
may be omitted. Records that match ALL provided fields will match; the name and
type comparisons are case insensitive. The rdata is compared for binary
equivalence, which means that IP addresses are normalized (e.g. 2001:db8::1 is
equal to 2001:db8::0:0:1), but also that the entire rdata must be exactly
equal.

When the MATCH has a `/regex/` instead of regular rdata, optionally ending in
`i` for case insensitive matches, the rdata is stringified and then matched
against the regex.

There are a few limitations for regexes: a regex containing a literal `/` is
currently not supported, not even if you escape it. Regex anchors like `^` and
`$` might produce unexpected results because the rdata string it's executed
against might be quoted. Similarly, there may be gaps in the data of long TXT
records. Keep your regexes short and simple.

Relative names are expanded using the _initial origin_ of the zone file (see
`--origin`).

`*` wildcards are supported for matching names. Wildcards are supported within
name parts (e.g. `ns*` will match `ns1` or `nsexample`) and subject to
origin expansion; `*.` (including the dot) can be used to match names outside
the file's _initial origin_.

`-first` is the default if you don't specify `-first` or `every`.

TTLs are ignored but this may change in a future version; don't use a TTL in a
match.

## --or-at-eof

When any match is given, `--or-at-eof` can be used to add the given record to
the end of the file if no match was found.

When `--add` is used without any matching rule, the given record will be added
to the end of the zone file unconditionally.

## --with RECORD

`--with` is the same as `--add`, but intended for use with `--replace`.

When an empty string (``), will comment the record.

## --delete

Instead of adding a `;` to comment the records replaced with `--replace
\--with ''`, delete them.

## --stdout, FILENAME

When no filename is given, a single zone file is expected on stdin, and the
output is given on stdout. When one or more filenames are given, the files will
be edited unless `--stdout` is used to output to stdout instead.

# CAVEATS

- `$INCLUDE` is intentionally not supported.
- If the original SOA serial number also occurs in the same SOA record
before the actual serial, the wrong thing is changed. This is unlikely to
happen.
- End-of-line comments on the same line as the matched record, are lost
when you use `--replace --delete`.
- There is currently no way to match a wildcard record without matching
non-wildcard records that would also match the wildcard.
- Garbage in, garbage out. If something in the input file could not be
parsed, it is kept as-is. If MATCH or RECORD is invalid, though, garbage may
end up in the output file. A dry run with `--stdout` is recommended whenever
you're trying something new.
- The class is IN. The separator is tab. These are currently not
configurable; use `--raw` if you want something more specific.

# DISCLAIMER

This free software does not come with any warranty. Use at your own risk.

Evaluate if this tool is good enough for your use case, before depending on it
in production. Even though it has been tested thoroughly, there may be bugs,
and due to the nature of DNS, such bugs could cause services to be rendered
unreachable. Any downtime caused by broken zone files is your own problem.

If this program does anything wrong, a bug report is appreciated. If it failed
spectacularly, please share the story for everyone's entertainment. :)

Don't forget to make a backup of any important file you change. Git is great
for zone files!

# AUTHOR

Juerd Waalboer <juerd@tnx.nl>
