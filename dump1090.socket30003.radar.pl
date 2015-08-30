#!/usr/bin/perl -w
# Ted Sluis 2015-08-20
# Filename : dump1090.socket30003.radar.pl
#
#===============================================================================
# Default setting:
my $default_max_altitude = 48000;
my $default_min_altitude = "0";
my $default_number_of_directions = 1440;
my $default_number_of_altitudezones = 16;
my $default_datadirectory = "/tmp";
my ($antenna_latitude,$antenna_longitude) = (52.085624,5.0890591); # Home location, default (Utrecht, The Netherlands)
#
#===============================================================================
use strict;
use POSIX qw(strftime);
use Time::Local;
use Getopt::Long;
use File::Basename;
use Math::Complex;
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
my $max_altitude;
my $min_altitude;
my $number_of_directions;
my $number_of_altitudezones;
my $lon;
my $lat;

GetOptions(
	"help!"=>\$help,
	"filemask=s"=>\$filemask,
	"data=s"=>\$datadirectory,
        "longitude=s"=>\$lon,
        "latitude=s"=>\$lat,
	"max=s"=>\$max_altitude,
	"min=s"=>\$min_altitude,
	"directions=s"=>\$number_of_directions,
	"zones=s"=>\$number_of_altitudezones
) or exit(1);
#
#===============================================================================
# Check options:
if ($help) {
	print "\nThis $scriptname script can sort flight data (lat, lon and alt).

Syntax: $scriptname

Optional parameters:
	-data <data directory>		The data files are stored in /tmp by default.
	-filemask <mask>		Specify a filemask. The default filemask is 'dump.socket*.txt'.
	-max <altitude>			Upper limit. Default is 48000. Higher values in the input data will be skipped.
	-min <altitude>			Lower limit. Default is 0. Lower values in the input data will be skipped.
	-directions <number>		Number of compass direction (pie slices). Minimal 8, maximal 7200. Default = 360.
	-zones <number>			Number of altitude zones. Minimal 1, maximum 99. Default = 16.
        -lon <lonitude>                 Location of your antenna.
        -lat <latitude>                 

Notes: 
- To launch it as a background process, add '&'.
- The default values can be change within the script (in the most upper section).

Examples:
	$scriptname 
	$scriptname -data /home/pi\n\n";
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
my $max = $max_altitude;
my $min = $min_altitude;
my $directions = $number_of_directions;
my $altitudezones = $number_of_altitudezones;
$max_altitude = $default_max_altitude if (!$max_altitude);
$min_altitude = $default_min_altitude if (!$min_altitude);
$number_of_directions = $default_number_of_directions if (!$number_of_directions);
$number_of_altitudezones = $default_number_of_altitudezones if (!$number_of_altitudezones);
my $error=0;
if ((($max) && ($max !~ /^\d+$/)) || ($max_altitude > 100000) || ($max_altitude <= $min_altitude)) {
	print "The maxium altitude ($max_altitude feet) is not valid! It should be at least as high as the minium altitude ($min_altitude feet), but not higher than 100.000 feet!\n";
	$error++;
} else {
	print "The maxium altitude is $max_altitude feet.\n";
}
if ((($min) && ($min !~ /^\d+$/)) || ($min_altitude < 0) || ($min_altitude >= $max_altitude)) {
	print "The minium altitude ($min_altitude feet) is not valid! It should be less than the maximum altitude ($max_altitude feet), but not less than 0 feet!\n";
	$error++;
} else {
 	print "The minimal altitude is $min_altitude feet.\n";
}
if ((($directions) && ($directions !~ /^\d+$/)) || ($number_of_directions < 8) || ($number_of_directions > 7200)) {
	print "The number of compass directions ($number_of_directions) is invalid! It should be at least 8 and less then 7200.\n";
	$error++;
} else {
	print "The number of compass directions (pie slices) is $number_of_directions.\n";
}
if ((($altitudezones) &&($altitudezones !~ /^\d+$/)) || ($number_of_altitudezones < 1) || ($number_of_altitudezones > 99)) {
	print "The number of altitude zones ($number_of_altitudezones) is invalid! It should be at least 1 and less than 100.\n";
} else {
	print "The number of altitude zones is $number_of_altitudezones.\n";
}
if ($error > 0) {
	exit 1;
}
# longitude & latitude
$antenna_longitude = $lon if ($lon);
if ($antenna_longitude !~ /^\d+(\.\d+)?$/) {
        print "The specified longitude '$antenna_longitude' is invalid!\n";
        exit 1;
}
$antenna_latitude = $lat if ($lat);
if ($antenna_latitude !~ /^\d+(\.\d+)?$/) {
        print"The specified latitude '$antenna_latitude' is invalid!\n";
        exit 1;
}
#
#===============================================================================
my $diff_altitude = $max_altitude - $min_altitude;
my $zone_altitude  = int($diff_altitude / $number_of_altitudezones);
print "An altitude zone is $zone_altitude feet.\n";
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
}
#===============================================================================
my $filecounter=0;
my $positioncounter=0;
my %positionperzonecounter;
my %positionperdirectioncounter;
# Read input files
foreach my $filename (@files) {
	my $positionsperfilecount=0;
	$filecounter++;
	chomp($filename);
	# Read data file
	open(my $data_filehandle, '<', $filename) or die "Could not open file '$filename' $!";
	while (my $line = <$data_filehandle>) {
		chomp($line);
		my @col = split(/,/,$line);
		# Remove any invalid position bigger than 600km
		next if ($col[$hdr{'distance'}] > 600000);
		# Skip if the altitude is out of range....
		next if (($col[$hdr{'altitude'}] < $min_altitude) || ($col[$hdr{'altitude'}] >= $max_altitude)); 
		# Display progress:
		my $back = length $positioncounter;
    		print $positionsperfilecount, substr "\b\b\b\b\b\b\b\b\b\b", 0, $back;
		# Calculate the altitude zone and direction zone
		my $altitude_zone  = sprintf("% 5d",int($col[$hdr{'altitude'}] / $zone_altitude ) * $zone_altitude);
		my $direction_zone = sprintf("% 4d",int($col[$hdr{'angle'}] * ($number_of_directions / 360)) / ($number_of_directions / 360));

		# Update the counters for statictics
		$positioncounter++;
		$positionsperfilecount++;
		$positionperzonecounter{$altitude_zone} = 0 if (!exists $positionperzonecounter{$altitude_zone});
		$positionperzonecounter{$altitude_zone}++;
		$positionperdirectioncounter{$altitude_zone}{$direction_zone} = 0 if (! exists $positionperdirectioncounter{$altitude_zone}{$direction_zone});
		$positionperdirectioncounter{$altitude_zone}{$direction_zone}++;
		# Save position if it is the most fare away location for it's altitude zone and direction zoe:
		if ((!exists $data{$altitude_zone}||(!exists $data{$altitude_zone}{$direction_zone})||($data{$altitude_zone}{$direction_zone}{'distance'} < $col[$hdr{'distance'}]))) {
			$data{$altitude_zone}{$direction_zone}{'distance'}   = $col[$hdr{'distance'}];
                        $data{$altitude_zone}{$direction_zone}{'hex_ident'}  = $col[$hdr{'hex_ident'}];
                        $data{$altitude_zone}{$direction_zone}{'altitude'}   = $col[$hdr{'altitude'}];
                        $data{$altitude_zone}{$direction_zone}{'latitude'}   = $col[$hdr{'latitude'}];
                        $data{$altitude_zone}{$direction_zone}{'longitude'}  = $col[$hdr{'longitude'}];
                        $data{$altitude_zone}{$direction_zone}{'date'}       = $col[$hdr{'date'}];
                        $data{$altitude_zone}{$direction_zone}{'time'}       = $col[$hdr{'time'}];
                        $data{$altitude_zone}{$direction_zone}{'angle'}      = $col[$hdr{'angle'}];

		}
	}
	close($data_filehandle);
}
print "\nNumber of files read: $filecounter\n";
print "Number of position processed: $positioncounter\n";
#===============================================================================
my @color = ("blue","yellow","red","green","violet","orange","cyan","magenta");
my $data_filehandle;
my $trackpoint=0;
my $track=0;
my $newtrack;
print "datafile=$datadirectory/graph1.csv\n";
open($data_filehandle, '>',"$datadirectory/radar.csv") or die "Unable to open '$datadirectory/radar.csv'!\n";
print $data_filehandle "type,new_track,name,color,trackpoint,altitudezone,destination,hex_ident,Altitude,latitude,longitude,date,time,angle,distance\n";
foreach my $altitude_zone (sort {$a<=>$b} keys %data) {
	$track++;
	my $alt_zone_name = sprintf("%05d-%5d",$altitude_zone,($altitude_zone + $zone_altitude));
	my $positionperzonecounter = sprintf("% 9d",$positionperzonecounter{$altitude_zone});
	my $tracknumber = sprintf("% 2d",$track);
	$newtrack = 1;
	my $min_positions_per_direction =0;
	my $max_positions_per_direction =0;
	foreach my $direction_zone (sort {$a<=>$b} keys %{$data{$altitude_zone}}) {
		my @row;
		foreach my $header (@header) {
			push(@row,$data{$altitude_zone}{$direction_zone}{$header});
		}
		$trackpoint++;
		# Determine color
		my $colornumber = $track;
		while ($colornumber > 7) {
			$colornumber = $colornumber - 8;
		}
		print $data_filehandle "T,$newtrack,Altitude zone $track: $alt_zone_name,$color[$colornumber],$trackpoint,$altitude_zone,$direction_zone,".join(",",@row)."\n";
		$newtrack = 0;
		$min_positions_per_direction = $positionperdirectioncounter{$altitude_zone}{$direction_zone} if ($positionperdirectioncounter{$altitude_zone}{$direction_zone} < $max_positions_per_direction);
		$max_positions_per_direction = $positionperdirectioncounter{$altitude_zone}{$direction_zone} if ($positionperdirectioncounter{$altitude_zone}{$direction_zone} > $max_positions_per_direction);
	}
	my $real_number_of_directions = scalar keys %{$positionperdirectioncounter{$altitude_zone}};
	my $avarage_positions_per_direction = sprintf("% 6d",($positionperzonecounter{$altitude_zone} / $number_of_directions));
	my $avarage_positions_per_real_direction =sprintf("% 6d",($positionperzonecounter{$altitude_zone} / $real_number_of_directions));
	my $line = sprintf("% 3d,Altitude zone:% 6d-% 6d,Directions:% 5d/% 5d,Positions processed:% 7d,Positions processed per direction: min:% 6d,max:% 6d,avg:% 6d,real avg:% 6d",$tracknumber,$altitude_zone,($altitude_zone + $zone_altitude-1),$real_number_of_directions,$number_of_directions,$positionperzonecounter{$altitude_zone},$min_positions_per_direction,$max_positions_per_direction,$avarage_positions_per_direction,$avarage_positions_per_real_direction);
	print $line."\n";
}

#===========================================================================
my $pi = atan2(1,1) * 4;
#
sub Asin (@) { 
	my $value1 = shift;
	my $value2 = (1 - $value1 * $value1);
	my $value3 = sqrt($value2);
	my $result = atan2($value1, $value3);
	print "value1=$value1, value2=$value2, value3=$value3, result=$result\n";
	return $result;
}
sub mod (@) {
	my $val1 = shift;
	my $val2 = shift;
	my $result = $val1 - $val2 * int($val1/$val2);
    	if ( $result < 0) {
		$result = $result + $val2;
	}
	return $result;
}
__END__
# lat =asin(sin(lat1)*cos(d)+cos(lat1)*sin(d)*cos(tc))
# dlon=atan2(sin(tc)*sin(d)*cos(lat1),cos(d)-sin(lat1)*sin(lat))
# lon=mod( lon1-dlon +pi,2*pi )-pi
#foreach my $diameter (50000,100000,150000,200000,250000,300000,350000,400000,450000,500000) {
foreach my $diameter (4500000,9000000,1800000) {
	$newtrack = 1;
	foreach my $direction_count (0..2880) {
		my $direction = $direction_count / 8;
		my $tc = $direction * $pi / 180;
		my $lat =Asin(sin($antenna_latitude) * cos($diameter) + cos($antenna_latitude) * sin($diameter) * cos($tc));
		my $dlon=atan2(sin($tc) * sin($diameter) * cos($antenna_latitude),cos($diameter) - sin($antenna_latitude) * sin($antenna_latitude));
 		my $lon=mod($antenna_longitude - $dlon + $pi,2 * $pi );# - $pi;
		$lat = $lat + $antenna_latitude;
		$trackpoint++;
		# T,0,Altitude zone 14: 39000-42000,cyan,2215, 39000, 176,72866B,39000,50.67630,5.18982,2015/04/09,23:51:36.155,176.070970267002,156858.033354566
		print $data_filehandle "T,$newtrack,Diameter $diameter,magenta,$trackpoint,,,,,$lat,$lon,-,-,$direction,$diameter\n";
		$newtrack = 0;
	}
}
