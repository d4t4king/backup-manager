#!/usr/bin/perl -w

use strict;
use warnings;
use feature qw( switch );
no warnings 'experimental::smartmatch';
use Term::ANSIColor;
use Data::Dumper;
use Getopt::Long qw( :config no_ignore_case bundling );
use File::Find;
use Date::Calc qw( Today Today_and_Now Delta_Days Localtime );;

push @INC, '.';
use Backup;

my ($help,$verbose,$start_dir,$wizard);
my ($period,$delete,$move,$show,$move_dir);
my (@files);
$verbose = 0;

GetOptions(
	'h|help'		=>	\$help,
	'v|verbose+'		=>	\$verbose,
	'd|startdir=s'		=>	\$start_dir,
	'w|wizard'		=>	\$wizard,
	'p|period=s'		=>	\$period,
	'D|delete'		=>	\$delete,
	's|show'		=>	\$show,
	'm|move'		=>	\$move,
	'M|movedir=s'		=>	\$move_dir,
);

&usage if ($help);

if ($wizard) {
	print "This wizard will gather some information about your environment and what you might want to accomplish.\n";
	print "What is your backup retention period, in days? ";
	my $ans = readline; chomp($ans);
	if ($ans =~ /^\d+$/) {
		$period = $ans;
	} else {
		die "Only numbers can be used for the retention period.\n";
	}
	print "Enter the starting directory: ";
	$start_dir = readline; chomp($start_dir);
	print "What would you like to do with the stale backup files? (Delete|Move|Show) ";
	$ans = readline; chomp($ans);
	given ($ans) {
		when (/[Dd](?:elete)?/) { $delete = 1; }
		when (/[Mm](?:ove)?/) { $move = 1; }
		when (/[Ss](?:how)?/) { $show = 1; }
		default { die "Unrecognized answer: ($ans) \n"; }
	}
}

&usage if ((!$start_dir) or ($start_dir eq ""));

if (!$period) {
	print "Retention period not specifying.  Defaulting to 30 days.\n";
	$period = 30;
}

my $time = time();

find(\&wanted, $start_dir);


#print Dumper(\@files);

my (%backups, %timeline);
foreach my $file ( @files ) {
	my $bak = Backup->new($file);
	$backups{$bak->backup_type}{$bak->backup_date} = $bak;
	$timeline{$bak->backup_date} = $bak;
}

#print Dumper(\%backups);
my %stales;

foreach my $type ( sort keys %backups ) {
	foreach my $bdate ( sort keys %{$backups{$type}} ) {
		if (&is_stale($backups{$type}{$bdate})) {
			push @{$stales{$type}}, $backups{$type}{$bdate};
		}
	}
}

#print Dumper(\%stales);

if ($show) {
	print "Backup timeline:\n";
	foreach my $bak ( sort { $a <=> $b } keys %timeline ) {
		if (&is_stale($timeline{$bak})) {
			print colored(localtime($bak)." ".$timeline{$bak}->backup_type."\t".$timeline{$bak}->size_gbytes." GB \n", "red");
		} else {
			print colored(localtime($bak)." ".$timeline{$bak}->backup_type."\t".$timeline{$bak}->size_gbytes." GB \n", "green");
		}
	}

	my $total_space = 0;
	print "Stales count:\n";
	foreach my $type ( sort keys %stales ) {
		print "$type: ".scalar(@{$stales{$type}})."\n";
		foreach my $stale ( @{$stales{$type}} ) {
			$total_space += $stale->size;
		}
	}

	print "You could recover ";
	if ($total_space <= 1024) {
		printf "%.3f bytes ", $total_space;
	} elsif ($total_space <= 1048576) {
		printf "%.3f KB ", ($total_space / 1024);
	} elsif ($total_space <= 1073741824) {
		printf "%.3f MB ", ($total_space / 1024 / 1024);
	} elsif ($total_space <= 1099511627776) {
		printf "%.3f GB ", ($total_space / 1024 / 1024 / 1024);
	} else {
		printf "%.3f TB ", ($total_space / 1048576 / 1048576);
	}
	print "by deleting stale backups.\n";
}
###############################################################################
# Subs
###############################################################################
sub wanted { next unless ($File::Find::dir =~ /$start_dir$/); -f && push @files, $File::Find::name; }

sub usage {
	print "Print the usage statement\n";
	exit 0;
}

sub is_stale {
	my $b_obj = shift;

	my ($tY,$tM,$tD,@t_rest) = Localtime($time);
	my ($bY,$bM,$bD,@b_rest) = Localtime($b_obj->backup_date);
	#print "T: $tY $tM $tD, Y: $bY $bM $bD ";
	my $dD = Delta_Days($bY,$bM,$bD,$tY,$tM,$tD);
	if ($dD >= $period) {
	#	print colored("$dD", "bold red");
		return 1;
	} else {
	#	print colored("$dD", "bold green");
		return 0;
	}
	#print "\n"; 
}
