#!/usr/bin/env perl
use strict;

=head1 SCRIPT

  This script dumps your Bareos catalog in ASCII format
  It works for MySQL, SQLite, and PostgreSQL

=head1 USAGE

    make_catalog_backup.pl MyCatalog

=head1 LICENSE

   BAREOS® - Backup Archiving REcovery Open Sourced

   Copyright (C) 2000-2010 Free Software Foundation Europe e.V.

   This program is Free Software; you can redistribute it and/or
   modify it under the terms of version three of the GNU Affero General Public
   License as published by the Free Software Foundation plus additions
   that are listed in the file LICENSE.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
   02110-1301, USA.

=cut

my $cat = shift or die "Usage: $0 catalogname";
my $dir_conf='/usr/sbin/bareos-dbcheck -B -c /etc/bareos';
my $wd = "/catalog_backup";

sub dump_sqlite3
{
    my %args = @_;

    exec("echo .dump | sqlite3 '$wd/$args{db_name}.db' > '$wd/$args{db_name}.sql'");
    print "Error while executing sqlite dump $!\n";
    return 1;
}

# TODO: use just ENV and drop the pg_service.conf file
sub dump_pgsql
{
    my %args = @_;
    umask(0077);

    if ($args{db_address}) {
        $ENV{PGHOST}=$args{db_address};
    }
    if ($args{db_socket}) {
        $ENV{PGHOST}=$args{db_socket};
    }
    if ($args{db_port}) {
        $ENV{PGPORT}=$args{db_port};
    }
    if ($args{db_user}) {
        $ENV{PGUSER}=$args{db_user};
    }
    if ($args{db_password}) {
        $ENV{PGPASSWORD}=$args{db_password};
    }
    $ENV{PGDATABASE}=$args{db_name};
    exec("HOME='$wd' pg_dump -c > '$wd/$args{db_name}.sql'");
    print "Error while executing postgres dump $!\n";
    return 1;               # in case of error
}

sub dump_mysql
{
    my %args = @_;
    umask(0077);
    unlink("$wd/.my.cnf");
    open(MY, ">$wd/.my.cnf")
        or die "Can't open $wd/.my.cnf for writing $@";

    $args{db_address} = $args{db_address} || "localhost";
    my $addr = "host=$args{db_address}";
    if ($args{db_socket}) {     # unix socket is fastest than net socket
        $addr = "socket=$args{db_socket}";
    }

    print MY "[client]
$addr
user=$args{db_user}
password=\"$args{db_password}\"
";
    if ($args{db_port}) {
        print MY "port=$args{db_port}\n";
    }

    close(MY);

    exec("HOME='$wd' mysqldump -f --opt $args{db_name} > '$wd/$args{db_name}.sql'");
    print "Error while executing mysql dump $!\n";
    return 1;
}

sub dump_catalog
{
    my %args = @_;
    if ($args{db_type} eq 'SQLite3') {
        $ENV{PATH}=":$ENV{PATH}";
        dump_sqlite3(%args);
    } elsif ($args{db_type} eq 'PostgreSQL') {
        $ENV{PATH}=":$ENV{PATH}";
        dump_pgsql(%args);
    } elsif ($args{db_type} eq 'MySQL') {
        $ENV{PATH}=":$ENV{PATH}";
        dump_mysql(%args);
    } else {
        die "This database type isn't supported";
    }
}

open(FP, "$dir_conf -C '$cat'|") or die "Can't get catalog information $@";
# catalog=MyCatalog
# db_type=SQLite
# db_name=regress
# db_driver=
# db_user=regress
# db_password=
# db_address=
# db_port=0
# db_socket=
my %cfg;

while(my $l = <FP>)
{
    if ($l =~ /catalog=(.+)/) {
        if (exists $cfg{catalog} and $cfg{catalog} eq $cat) {
            exit dump_catalog(%cfg);
        }
        %cfg = ();              # reset
    }

    if ($l =~ /(\w+)=(.+)/) {
        $cfg{$1}=$2;
    }
}

if (exists $cfg{catalog} and $cfg{catalog} eq $cat) {
    exit dump_catalog(%cfg);
}

print "Can't find your catalog ($cat) in director configuration\n";
exit 1;
