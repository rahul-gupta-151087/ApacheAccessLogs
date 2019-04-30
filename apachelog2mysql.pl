#!/usr/bin/perl

############################################################################################################
# apachelog2mysql.pl
#
# Apache log(s) to MySQL table
#
# Usage: ./{file} {log path(s)} {mysql db credentials}
# Example: ./{file} "/dir1/log1, /dir2/log2" "db_host:db_database:db_username:db_password"
#
############################################################################################################
use strict;
use warnings;
use DBI;

my %conf = (
	"table_name" => "apachelog"
);

if(@ARGV < 2)
{
	print "Usage: " . __FILE__ . " {log path(s)} {mysql db credentials}\n"
		. "Example: " . __FILE__ . " \"/dir1/log1, /dir2/log2\" "
		. "\"db_host:db_database:db_username:db_password\"\n\n";
	exit;
}

my ($arg_logs) = $ARGV[0];
my ($arg_db) = $ARGV[1];

my @logs = split(',', $arg_logs);
my @db = split(':', $arg_db);
if(@db < 4)
{
	print "Failed to continue, invalid DB configuration settings\n\n";
	exit;
}

my $lines = 0;
foreach(@logs)
{
	my $log = $_;
	$log =~ s/^\s+//; # rem lead spaces
	$log =~ s/\s+$//; # rem tail spaces
	processLog($log);
}

print "\nTotal log entries inserted: " . $lines . "\n\n";

sub processLog
{
	my $log = $_[0];
	print "\nProcessing log \"" . $log . "\"...\n";
	
	open my $data, $log or die "\nFailed to open log file: \"" . $log . "\"\n\n";
	
	my $dbc = DBI->connect('DBI:mysql:' . $db[1] . ':' . $db[0], 
		$db[2], $db[3], { RaiseError => 1 })
		or die "\nFailed to connect to database \"" . $db[1] . "\"";
	
	initDB($dbc);
	
	while(my $line = <$data>)
	{
		chomp($line);
		$line =~ s/'/\\'/g; # ' to \' for db
		if(length($line) > 1)
		{
			my ($created, $type, $ip, $msg) = $line =~ 
				m/^\[([^\]]+)\]\s\[([^\]]+)\]\s\[(?:client\s)?([^\]]+)\]\s?(.*)/;
			my $q = "INSERT IGNORE INTO " . $conf{'table_name'} 
				. "(log, stored, created, type, ip, message, mhash) VALUES('" 
				. $log . "', NOW(),'" . $created . "','" . $type . "','" . $ip 
				. "','" . $msg . "',md5('" . $msg . "'));";
			my $dbs = $dbc->prepare($q);
			$lines = $lines + $dbs->execute() or print "\nFailed to insert line \"" . $line . "\"\n";
		}
	}
	
	$dbc->disconnect;
	
	close $data;
	close $log;
	
	# flush log file
	`echo '' > $log`;
}

my $is_db_ready = 0;
sub initDB
{
	if(!$is_db_ready)
	{
		print "Initializing database...\n";
		
		my $dbc = $_[0];
		
		my $dbs = $dbc->prepare("
			CREATE TABLE IF NOT EXISTS `" . $conf{'table_name'} . "` (
			  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
			  `log` varchar(255) NOT NULL,
			  `stored` timestamp NULL DEFAULT NULL,
			  `created` varchar(255) DEFAULT NULL,
			  `type` varchar(50) DEFAULT NULL,
			  `ip` varchar(255) DEFAULT NULL,
			  `message` mediumtext NOT NULL,
			  `mhash` char(32) NOT NULL,
			  PRIMARY KEY (`id`),
			  UNIQUE KEY `entry_unique` (`log`,`type`,`mhash`)
			) ENGINE=MyISAM AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;
		");
		
		$dbs->execute() or die "\nFailed to execute create table \"" 
			. $conf{'table_name'} . "\" query\n";
		
		$is_db_ready = 1;
	}
}
