#!/usr/bin/perl -w
#
# Ted Sluis 2015-09-06-24
# heatmap.pl
#
#===============================================================================
BEGIN {
	use strict;
	use POSIX qw(strftime);
	use Time::Local;
	use Getopt::Long;
	use File::Basename;
	use Cwd 'abs_path';
	our $scriptname  = basename($0);
        our $fullscriptname = abs_path($0);
        use lib dirname (__FILE__);
        use common;
}
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
#===============================================================================
# Read settings from config file
my %setting = common->READCONFIG('socket30003.cfg',$fullscriptname);
# Use parameterS & values from the 'heatmap' section. If empty or not-exists, then use from the 'common' section, otherwise script defaults.
my $default_datadirectory = $setting{'heatmap'}{'defaultdatadirectory'} || $setting{'common'}{'defaultdatadirectory'} || "/tmp";
my $outputfile            = $setting{'heatmap'}{'outputfile'}           || $setting{'common'}{'outputfile'}           || "heatmapcode.csv";
my $outputdatafile	  = $setting{'heatmap'}{'outputdatafile'}       || $setting{'common'}{'outputdatafile'}       || "heatmapdata.csv";
my $latitude              = $setting{'heatmap'}{'latitude'}             || $setting{'common'}{'latitude'}             || 52.085624; # Antenna location
my $longitude             = $setting{'heatmap'}{'longitude'}            || $setting{'common'}{'longitude'}            || 5.0890591; # 
my $degrees               = $setting{'heatmap'}{'degrees'}              || 5;        # used to determine boundary of area around antenne.
my $resolution            = $setting{'heatmap'}{'resolution'}           || 1000;     # number of horizontal and vertical positions in output file.
my $max_positions         = $setting{'heatmap'}{'max_positions'}        || 100000;   # maximum number of positions in the outputfile.
my $max_weight            = $setting{'heatmap'}{'max_weight'}           || 1000;     # maximum position weight on the heatmap.
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
	"maxweight=s"=>\$max_weight,
) or exit(1);
#
#===============================================================================
# Check options:
if ($help) {
	print "\nThis $scriptname script creates heatmap data 
which can be displated in a modified variant of dump1090-mutobility.

It creates two output files:
1) One file with locations in java script code, which must be added
   to the script.js manualy.
2) One file with location data in csv format, which can be imported
   from the dump1090 GUI.

Please read this post for more info:
http://discussions.flightaware.com/post180185.html#p180185

This script uses the output file(s) of the 'socket30003.pl'
script, which are by default stored in /tmp in this format:
dump1090-<hostname/ip_address>-YYMMDD.txt

The script will automaticly use the correct units (feet, meter, 
kilometer, mile, natical mile) for 'altitude' and 'distance' when 
the input files contain column headers with the unit type between 
parentheses. When the input files doesn't contain column headers 
(as produced by older versions of 'socket30003.pl' script)
you can specify the units. Otherwise this script will use the 
default units.

This script will create a heatmap of a square area around your 
antenna. You can change the default range by specifing the number
of degrees -/+ to your antenna locations. This area will be devided
in to small squares. The default heatmap has a resolution of 
1000 x 1000 squares. The script will read all the flight position 
data from the input file(s) and count the times they match with a 
square on the heatmap. 

The more positions match with a particular square on the heatmap, 
the more the 'weight' that heatmap position gets. We use only the 
squares with the most matches (most 'weight) 'to create the heatmap.
This is because the map in the browser gets to slow when you use 
too much positions in the heatmap. Of cource this also depends on 
the amount of memory of your system. You can change the default 
number of heatmap positions. You can also set the maximum of 
'weight' per heatmap position. 

Syntax: $scriptname

Optional parameters:
	-data <data directory>          The data files are stored in /tmp by default.
	-filemask <mask>                Specify a filemask. The default filemask is 'dump*.txt'.
        -lon <lonitude>                 Location of your antenna.
        -lat <latitude>
	-maxpositions <max positions>   Default is 100000 positions.
	-maxweight <number>		Maximum position weight on the heatmap. The default is 1000.
	-resolution <number>            Number of horizontal and vertical positions in output file.
	                                Default is 1000, which means 1000x1000 positions.
	-degrees <number>               To determine boundaries of area around the antenna.
	                                (lat-degree <--> lat+degree) x (lon-degree <--> lon+degree)
	                                De default is 5 degree.
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
        $degrees = 5;
}
my $factor = int($resolution / ($degrees * 2));
#===============================================================================
# Max positions
if ($max_positions) {
	if (($max_positions !~ /^\d{3,6}$/) && ($max_positions > 99) && ($max_positions < 1000000)) {
		print "The maximum number of positions '$max_positions' is invalid!\n";
		print "It should be between 100 and 999999.\n";
		exit;
	} 
} else {
	$max_positions = 100000;
}
print "There will be no more then '$max_positions' positions in the output file.\n";
#===============================================================================
if ($max_weight) {
        if (($max_weight !~ /^\d{2,4}$/) && ($max_weight > 9) && ($max_weight < 10000)) {
                print "The maximum position weight '$max_weight' is invalid!\n";
                print "It should be between 10 and 9999.\n";
                exit;
        }
} else {
        $max_weight = 1000;
}
print "The maximum position weight on the heatmap will be not more then '$max_weight'.\n";
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
$longitude =~ s/,/\./ if ($longitude);
if ($longitude !~ /^[-+]?\d+(\.\d+)?$/) {
	print "The specified longitude '$longitude' is invalid!\n";
	exit 1;
}
$latitude = $lat if ($lat);
$latitude  =~ s/,/\./ if ($latitude);
if ($latitude !~ /^[-+]?\d+(\.\d+)?$/) {
	print"The specified latitude '$latitude' is invalid!\n";
	exit 1;
}
# area around antenna
$latitude  = int($latitude  * 1000) / 1000;
$longitude = int($longitude * 1000) / 1000;
my $lat1 = int(($latitude  - $degrees) * 10) / 10; # most westerly latitude
my $lat2 = int(($latitude  + $degrees) * 10) / 10; # most easterly latitude
my $lon1 = int(($longitude - $degrees) * 10) / 10; # most northerly longitude
my $lon2 = int(($longitude + $degrees) * 10) / 10; # most southerly longitude
print "The resolution op the heatmap will be ${resolution}x${resolution}.\n";
print "The antenna latitude & longitude are: '$latitude','$longitude'.\n";
print "The heatmap will cover the area of $degrees degree around the antenna, which is between latitude $lat1 - $lat2 and longitude $lon1 - $lon2.\n";
#===============================================================================
my %data;
# Set default filemask
if (!$filemask) {
	$filemask = "'dump*.txt'" ;
} else {
	$filemask ="'*$filemask*'";
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
$outputdatafile = "$datadirectory/$outputdatafile";
open(my $output, '>', "$outputfile") or die "Could not open file '$outputfile' $!";
open(my $outputdata, '>', "$outputdatafile") or die "Could not open file '$outputdatafile' $!";
print $outputdata "\"weight\";\"lat\";\"lon\"";
# Read input files
foreach my $filename (@files) {
	chomp($filename);
	# Read data file
	open(my $data_filehandle, '<', $filename) or die "Could not open file '$filename' $!";
	print "Processing file '$filename':\n";
	my $outside_area = 0;
	my $linecounter = 0;
        my @header;
        my %hdr;
	while (my $line = <$data_filehandle>) {
		chomp($line);
		$linecounter++;
                # Data Header
                # First line? 
                if (($linecounter == 1) || ($line =~ /hex_ident/)){
			print "- ".($linecounter-1)." processed.\n" if ($linecounter != 1);
                	# Reset fileunit:
                        #%fileunit =();
                        # Does it contain header columns?
                        if ($line =~ /hex_ident/) {
				@header = ();
                        	my @unit;
                                # Header columns found!
                                my @tmp = split(/,/,$line);
                                foreach my $column (@tmp) {
                        	        if ($column =~ /^\s*([^\(]+)\(([^\)]+)\)\s*$/) {
                                		# The column name includes a unit, for example: altitude(meter)
                                        	push(@header,$1);
                                	        #$fileunit{$1} = $2;
                                        	push(@unit,"$1=$2");
                                	} else {
                                		push(@header,$column);
                                	}
                      		}
                        	print "  -header units:".join(",",@unit).", position $linecounter";
                      	} else {
                        	# No header columns found. Use default!
                                @header = ("hex_ident","altitude","latitude","longitude","date","time","angle","distance");
				print "  -default units, position $linecounter";
                        }
                       	# The file header unit information may be changed: set the units again.
                        #setunits;
                        my $columnnumber = 0;
                        # Save column name with colomn number in hash.
                        foreach my $header (@header) {
                        	$hdr{$header} = $columnnumber;
                        	$columnnumber++;
           		}
                	next if ($line =~ /hex_ident/);
                }
		# split columns into array values:
		my @col = split(/,/,$line);
		$lat = $col[$hdr{'latitude'}];
		$lon = $col[$hdr{'longitude'}];
		# remove lat/lon position that are to fare away.
		if (($lat < $lat1) || ($lat > $lat2) || ($lon < $lon1) || ($lon > $lon2)) {
			$outside_area++;
			next;
		}
		$lat = int((int(($lat - $latitude ) * $factor) / $factor + $latitude ) * 1000) / 1000;
		$lon = int((int(($lon - $longitude) * $factor) / $factor + $longitude) * 1000) / 1000;
		# count the number of time a lat/lon position was recorded:
		$pos{$lat}{$lon} = 0 if (!exists $pos{$lat}{$lon} );
		$pos{$lat}{$lon} += 1;
	}
	print "-".($linecounter-1)." processed. $outside_area positions were out side the specified area.\n";
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
# Get the highest :
my ($highest_weight,@rubbishi)= reverse sort keys %sort;
$highest_weight =~ s/,.+,.+$//;
# Get lowest weight:
my $counter = 0;
my $lowest_weight;
foreach my $sort (reverse sort keys %sort) {
        my ($weight,$lat,$lon) = split(/,/,$sort);
        $counter++;
        # stop after the maximum number of heatmap positions is reached or the weight to low:
        if (($counter >= $max_positions) || ($weight < 3)){
		$lowest_weight = $weight;
		last;
	}
}
print "The highest weight is '$highest_weight' and the lowest weight is '$lowest_weight'.\n";
# Is the highest weight more then the maximum weight?
if ($max_weight > $highest_weight){
	$max_weight = $highest_weight;
} else {
	print "Since the highest weight is more the the max weight '$max_weight' the weight of all points will be multiplied with a factor ".($max_weight / $highest_weight).".\n";
}
# Proces the positions. Start with the positions that most occured in the flight position data.
$counter = 0;
foreach my $sort (reverse sort keys %sort) {
	my ($weight,$lat,$lon) = split(/,/,$sort);
	last if ($weight < 3);
	$weight = int(($max_weight / $highest_weight * $weight) + ($lowest_weight * $max_weight / $highest_weight * (($highest_weight - $weight) / $highest_weight)) + 1); 
	$counter++;
	# stop after the maximum number of heatmap positions is reached:
	last if ($counter >= $max_positions);
	# print output to file:
	print $output "{location: new google.maps.LatLng($lat, $lon), weight: $weight},\n";
	print $outputdata "\n\"$weight\";\"$lat\";\"$lon\"";
}
close($output);
close($outputdata);
# print a summery of the result:
print "\nOutput file with java script code: $outputfile\n";
my @cmd = `head -n 5 $outputfile`;
print join("",@cmd);
print "\n$counter rows with heatmap position data processed!\n\n";
@cmd = `tail -n 5 $outputfile`;
print join("",@cmd);
#
print "\nOutput file in csv format: $outputdatafile\n";
@cmd = `head -n 5 $outputdatafile`;
print join("",@cmd);
print "\n$counter rows with heatmap position data processed!\n\n";
@cmd = `tail -n 5 $outputdatafile`;
print join("",@cmd)."\n";
