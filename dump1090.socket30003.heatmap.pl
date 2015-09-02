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
my $degrees = 3;                  # used to determine boundary of area around antenne.
my $resolution = 1000;            # number of horizontal and vertical positions in output file.
my $max_positions = 100000;       # maximum number of positions in the outputfile.
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
        "latitude=s"=>\$lat,
	"maxpositions=s"=>\$max_positions,
	"resolution=s"=>\$resolution,
	"degrees=s"=>\$degrees,
) or exit(1);
#
#===============================================================================
# Check options:
if ($help) {
	print "\nThis $scriptname script can create heatmap data.
At this moment it only creates a file with java script code, which
must be add to the script.js manualy in order to get a heatmap layer.
Please read this post for more info:
http://discussions.flightaware.com/ads-b-flight-tracking-f21/heatmap-for-dump1090-mutability-t35844.html

Syntax: $scriptname

Optional parameters:
	-data <data directory>          The data files are stored in /tmp by default.
	-filemask <mask>                Specify a filemask. The default filemask is 'dump.socket*.txt'.
        -lon <lonitude>                 Location of your antenna.
        -lat <latitude>
	-maxpositions <max positions>   Default is 100000 positions.
	-resolution <number>            Number of horizontal and vertical positions in output file.
	                                Default is 1000, which means 1000x1000 positions.
	-degrees <number>               To determine boundaries of area around the antenna.
	                                (lat-degree -- lat+degree) x (lon-degree -- lon+degree)
	                                De default is 3 degree.
	-help				This help page.

note: 
	The default values can be changed within the script (in the most upper section).


Examples:
	$scriptname 
	$scriptname -data /home/pi
	$scriptname -lat 52.1 -lon 4.1 -maxposition 50000\n\n";
	exit 0;
}
#===============================================================================
# Resolution, Degrees & Factor
if ($resolution) {
	if ($resolution !~ /^\d{2,5}$/) {
                print "The resolution '$resolution' is invalid!\n";
                print "It should be between 10 and 99999.\n";
                exit;
        }
} else {
        $resolution = 1000;
}
if ($degrees) {
        if ($degrees !~ /^\d{1,2}(\.\d{1,4})?$/) {
                print "The given number of degrees '$degrees' is invalid!\n";
                print "It should be between 0.0001 and 99.9999 degrees.\n";
                exit;
        }
} else {
        $degrees = 3;
}
my $factor = int($resolution / ($degrees * 2));
# area around antenna
my $lat1 = int(($latitude  - $degrees) * 1000) / 1000; # most westerly latitude
my $lat2 = int(($latitude  + $degrees) * 1000) / 1000; # most easterly latitude
my $lon1 = int(($longitude - $degrees) * 1000) / 1000; # most northerly longitude
my $lon2 = int(($longitude + $degrees) * 1000) / 1000; # most southerly longitude
print "The resolution op the heatmap will be ${resolution}x${resolution}.\n";
#===============================================================================
# Max positions
if ($max_positions) {
	if ($max_positions !~ /^\d{3,6}$/) {
		print "The maximum number of positions '$max_positions' is invalid!\n";
		print "It should be between 100 and 999999.\n";
		exit;
	} 
} else {
	$max_positions = 100000;
}
print "There will be no more then '$max_positions' positions in the output file.\n";
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
print "The antenna latitude & longitude are: '$latitude','$longitude'.\n";
print "The heatmap will cover the area of $degrees degree around the antenna, which is between latitude $lat1 - $lat2 and longitude $lon1 - $lon2.\n";
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
	my @tmp;
	foreach my $file (@files) {
		chomp($file);
		next if ($file =~ /log$|pid$/i);
		print "  $file\n";
		push(@tmp,$file);
	}
	@files = @tmp;
	if (@files == 0) {
        	print "No files were found in '$datadirectory' that matches with the '$filemask' filemask!\n";
        	exit 1;
	}
}
#===============================================================================
my %pos;
$outputfile = "$datadirectory/$outputfile";
open(my $output, '>', "$outputfile") or die "Could not open file '$outputfile' $!";
# Read input files
foreach my $filename (@files) {
	chomp($filename);
	# Read data file
	open(my $data_filehandle, '<', $filename) or die "Could not open file '$filename' $!";
	print "Processing file '$filename'";
	my $positions = 0;
	my $outside_area;
	while (my $line = <$data_filehandle>) {
		chomp($line);
		# split columns into array values:
		my @col = split(/,/,$line);
		$positions++;
		$lat = $col[$hdr{'latitude'}];
		$lon = $col[$hdr{'longitude'}];
		# remove lat/lon position that are to fare away.
		if (($lat < $lat1) || ($lat > $lat2) || ($lon < $lon1) || ($lon > $lon2)) {
			$outside_area++;
			next;
		}
		$lat = int(($lat - $lat1) * $factor) / $factor + $lat1;
		$lon = int(($lon - $lon1) * $factor) / $factor + $lon1;
		# count the number of time a lat/lon position was recorded:
		$pos{$lat}{$lon} = 0 if (!exists $pos{$lat}{$lon} );
		$pos{$lat}{$lon} += 1;
	}
	print ", '$positions' positions processed. $outside_area positions were out side the specified area.\n";
	close($data_filehandle);
}
# Sort positions based on the number of times they occured in the flight position data.
my %sort;
foreach my $lat (keys %pos) {
	foreach my $lon (keys %{$pos{$lat}}) {
		my $number = sprintf("%08d",$pos{$lat}{$lon}); 
		# Save lat/lon sorted by the number of times they were recorded
		$sort{"$number,$lat,$lon"} = 1;
	}
}
print "Number of sorted positions: ".(keys %sort)."\n";
my $counter = 0;
# Proces the positions. Start with the positions that most occured in the flight position data.
foreach my $sort (reverse sort keys %sort) {
	my ($number,$lat,$lon) = split(/,/,$sort);
	$counter++;
	# stop after the 100000 most recorded positions:
	last if ($counter >= $max_positions);
	# print output to file:
	print $output "{location: new google.maps.LatLng($lon, $lat), weight: $number},\n";
}
close($output);
# print a summery of the result:
print "Output file: $outputfile\n";
my @cmd = `head -n 5 $outputfile`;
print join("",@cmd);
print "\n$counter rows with heatmap position data processed!\n\n";
@cmd = `tail -n 5 $outputfile`;
print join("",@cmd);
