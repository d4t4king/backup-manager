#!/usr/bin/perl -w

package Backup;

use strict;
use warnings;
use Data::Dumper;
use Term::ANSIColor;
use File::Basename;
use POSIX;

require Exporter;

our @EXPORT		= qw( );
our @EXPORT_OK	= qw( );

{
	$Backup::VERSION	= '0.0.1';
}

my $self;

sub new {
	my $class = shift;
	$self->{'fullfilename'}	= shift;
	&_parseObject($self);
	bless $self, $class;
	return $self;
}

sub _parseObject {
	my $self = shift;
	my @suffix_list = qw( tar.gz tar.xz tgz tar.Z tar.bz2 );
	my ($base,$dir,$suffix) = fileparse($self->{'fullfilename'}, @suffix_list);
	#print colored("\n$dir|$base|$suffix\n", "yellow");
	$self->{'dirname'} = $dir;
	$self->{'suffix'} = $suffix;
	$base =~ s/(.*)\.$/$1/;
	$self->{'filename'} = "$base\.$suffix";
	my @parts = split(/\_/, $base);
	#print Dumper(\@parts);
	$self->{'backup_type'} = $parts[0];
	$self->{'raw_date'} = $parts[1];
	$parts[2] =~ s/(.*)\.$/$1/;
	$self->{'host'} = $parts[2];
	my @fstat = stat($self->{'fullfilename'});
	$self->{'file_mode'} = $fstat[2];
	$self->{'owner_uid'} = $fstat[5];
	$self->{'owner_gid'} = $fstat[6];
	$self->{'size'} = $fstat[7];
	$self->{'atime'} = $fstat[8];
	$self->{'mtime'} = $fstat[9];
	$self->{'ctime'} = $fstat[10];
}

### Properties

sub backup_host {
	my $self = shift;
	return $self->{'host'};
}

sub backup_date {
	my $self = shift;
	my ($y,$m,$d,$H,$M,$S) = split(/\-/, $self->{'raw_date'});
	$y = $y - 1900;
	$m = $m - 1;
	my $utime = mktime($S,$M,$H,$d,$m,$y,0,0);
	return $utime;
}

sub backup_type {
	my $self = shift;
	return $self->{'backup_type'};
}

sub directory {
	my $self = shift;
	return $self->{'dirname'};
}

sub filename {
	my $self = shift;
	return $self->{'filename'};
}

sub fullfilename {
	my $self = shift;
	return $self->{'fullfilename'};
}

sub size {
	my $self = shift;
	return $self->{'size'};
}

sub size_kbytes {
	my $self = shift;
	return sprintf("%.2f", ($self->{'size'} / 1024));
}

sub size_mbytes {
	my $self = shift;
	return ($self->{'size'} / 1024 / 1024);
}

sub size_gbytes {
	my $self = shift;
	return ($self->{'size'} / 1024 / 1024 / 1024);
}

sub size_tbytes {
	my $self = shift;
	return ($self->{'size'} / 1024 / 1024 / 1024 / 1024);
}

1;
