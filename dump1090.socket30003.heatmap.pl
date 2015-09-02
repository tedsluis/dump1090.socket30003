#!/usr/bin/perl -w
#
# Ted Sluis 2015-09-02
# dump1090.socket30003.heatmap.pl
#
#===============================================================================
# Default setting:
my $default_datadirectory = "/tmp";
my $outputfile ="heatmap.csv";
my ($latitude,$longitude) = (52.085624,5.0890591); # Antenna location
my $lat1 = $latitude  - 5; # most westerly latitude
my $lat2 = $latitude  + 5; # most easterly latitude
my $lon1 = $longitude - 5; # most northerly longitude
my $lon2 = $longitude + 5; # most southerly longitude
#
#===============================================================================
use strict;
use POSIX qw(strftime);
use Time::Local;
use Getopt::Long;
use File::Basename;
my $scriptname  = basename($0);
#
#===============================================================================
# Ctrl-C interupt handler
$SIG{'INT'} = \&intHandler;

sub intHandler {
	# Someone pressed Ctrl-C
	print "\nCTRL-C was pressed. Do you want to exit '$scriptname'? (y/n)\n";
	my $answer = <STDIN>;
	if ($answer =~ /^y$/i) {
		print "Exiting '$scriptname'.....\n";
		exit 1;
	} else {
		print "'$scriptname' is continuing.......\n";
	}
}
#
#===============================================================================
# Get options
my $help;
my $datadirectory;
my $filemask;
my $lon;
my $lat;


GetOptions(
	"help!"=>\$help,
	"filemask=s"=>\$filemask,
	"data=s"=>\$datadirectory,
        "longitude=s"=>\$lon,
        "latitude=s"=>\$lat
) or exit(1);
#
#===============================================================================
# Check options:
if ($help) {
	print "\nThis $scriptname script can create heatmap data

Syntax: $scriptname

Optional parameters:
	-data <data directory>		The data files are stored in /tmp by default.
	-filemask <mask>		Specify a filemask. The default filemask is 'dump.socket*.txt'.
        -lon <lonitude>                 Location of your antenna.
        -lat <latitude>
	-help				This help page.

note: 
	The default values can be change within the script (in the most upper section).


Examples:
	$scriptname 
	$scriptname -data /home/pi
	$scriptname -lat 52.1 -lon 4.1\n\n";
	exit 0;
}
#=============================================================================== 
# Are the specified directories for data, log and pid file writeable?
$datadirectory = $default_datadirectory if (!$datadirectory);
if (!-w $datadirectory) {
	print "The directory does not exists or you have no write permissions in data directory '$datadirectory'!\n";
	exit 1;
}
#===============================================================================
# longitude & latitude
$longitude = $lon if ($lon);
if ($longitude !~ /^[-+]?\d+(\.\d+)?$/) {
	print "The specified longitude '$longitude' is invalid!\n";
	exit 1;
}
$latitude = $lat if ($lat);
if ($latitude !~ /^[-+]?\d+(\.\d+)?$/) {
	print"The specified latitude '$latitude' is invalid!\n";
	exit 1;
}
print "The antenna latitude & longitude are: '$latitude','$longitude'\n";
#                                 
#===============================================================================
# Data Header
my @header = ("hex_ident","altitude","latitude","longitude","date","time","angle","distance");
my %hdr;
my $columnnumber = 0;
# Save colum name with colomn number in hash.
foreach my $header (@header) {
        $hdr{$header} = $columnnumber;
        $columnnumber++;
}
#===============================================================================
my %data;
# Set default filemask
if (!$filemask) {
	$filemask = "dump.socket*.txt" ;
} else {
	$filemask ="*$filemask*";
}
# Find files
my @files =`find $datadirectory -name $filemask`;
if (@files == 0) {
	print "No files were found in '$datadirectory' that matches with the '$filemask' filemask!\n";
	exit 1;
} else {
	print "The following files fit with the filemask '$filemask':\n";
	foreach my $file (@files) {
		print "  $file\n";
	}
}
#===============================================================================
my %pos;
open(my $output, '>', "$datadirectory/$outputfile") or die "Could not open file '$datadirectory/outputfile' $!";
# Read input files
foreach my $filename (@files) {
	chomp($filename);
	# Read data file
	open(my $data_filehandle, '<', $filename) or die "Could not open file '$filename' $!";
	print "Processing file $filename";
	my $positions = 0;
	while (my $line = <$data_filehandle>) {
		chomp($line);
		# split columns into array values:
		my @col = split(/,/,$line);
		# Remove any invalid position bigger than 600km
		next if ($col[$hdr{'distance'}] > 600000);
		$lat = $col[$hdr{'latitude'}];
		$lon = $col[$hdr{'longitude'}];
		# remove lat/lon position that are to fare away.
		next if (($lat < $lat1) || ($lat > $lat2) || ($lon < $lon1) || ($lon > $lon2));
		my $factor =100; # low factor means less points, high factor gives more points.
		$lat = int(($lat - $lat1) * $factor) / $factor + $lat1;
		$lon = int(($lon - $lon1) * $factor) / $factor + $lon1;
		# count the number of time a lat/lon position was recorded:
		$pos{$lat}{$lon} = 0 if (!exists $pos{$lat}{$lon} );
		$pos{$lat}{$lon} += 1;
		$positions++;
	}
	print ", $positions processed.\n";
	close($data_filehandle);
}
my %sort;
foreach my $lat (keys %pos) {
	foreach my $lon (keys %{$pos{$lat}}) {
		my $number = sprintf("%08d",$pos{$lat}{$lon}); 
		# Save lat/lon sorted by the number of times they were recorded
		$sort{"$number,$lat,$lon"} = 1;
	}
}
my $counter = 0;
foreach my $sort (reverse sort keys %sort) {
	my ($number,$lat,$lon) = split(/,/,$sort);
	$counter++;
	# stop after the 100000 most recorded positions:
	last if ($counter > 100000);
	# print output to screen:
	print  "$counter $lat $lon   (number = $number)\n";
	# print output to file:
	print $output "{location: new google.maps.LatLng($lon, $lat), weight: $number},\n";
}
close($output);

