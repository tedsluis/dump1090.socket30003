#!/usr/bin/perl -w
# Ted Sluis 2015-12-21
# Filename : rangeview.pl
#
#===============================================================================
BEGIN {
	use strict;
	use POSIX qw(strftime);
	use Time::Local;
	use Getopt::Long;
	use File::Basename;
	use Math::Complex;
        use Cwd 'abs_path';
        our $scriptname  = basename($0);
        our $fullscriptname = abs_path($0);
        use lib dirname (__FILE__);
        use common;
	my $scriptname  = basename($0);
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
# Use parameters & values from the 'heatmap' section. If empty or not-exists, then use from the 'common' section, otherwise script defaults.
$default_max_altitude_meter      = $setting{'rangeview'}{'default_max_altitude_meter'}      || 12000; # specified in meter
$default_max_altitude_feet       = $setting{'rangeview'}{'default_max_altitude_feet'}       || 36000; # specified in feet
$default_min_altitude            = $setting{'rangeview'}{'default_min_altitude'}            || "0";   # specified in the output unit
$default_number_of_directions    = $setting{'rangeview'}{'default_number_of_directions'}    || 1440;  # 
$default_number_of_altitudezones = $setting{'rangeview'}{'default_number_of_altitudezones'} || 24;
$default_datadirectory           = $setting{'rangeview'}{'defaultdatadirectory'}            || $setting{'common'}{'defaultdatadirectory'} || "/tmp";
$defaultdistanceunit             =($setting{'rangeview'}{'defaultdistanceunit'}             || $setting{'common'}{'defaultdistanceunit'}  || "kilometer").','.
                                  ($setting{'rangeview'}{'defaultdistanceunit'}             || $setting{'common'}{'defaultdistanceunit'}  || "kilometer"); # specify input & output unit! kilometer, nauticalmile, mile or meter
$defaultaltitudeunit             =($setting{'rangeview'}{'defaultaltitudeunit'}             || $setting{'common'}{'defaultaltitudeunit'}  || "meter").','.
                                  ($setting{'rangeview'}{'defaultaltitudeunit'}             || $setting{'common'}{'defaultaltitudeunit'}  || "meter");     # specify input & output unit! meter or feet
$antenna_latitude                = $setting{'rangeview'}{'latitude'}                        || $setting{'common'}{'latitude'}             || 52.085624;    # Home location, default (Utrecht, The Netherlands)
$antenna_longitude               = $setting{'rangeview'}{'longitude'}                       || $setting{'common'}{'longitude'}            || 5.0890591; 
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
        "distanceunit=s"=>\$defaultdistanceunit,
        "altitudeunit=s"=>\$defaultaltitudeunit,
	"max=s"=>\$max_altitude,
	"min=s"=>\$min_altitude,
	"directions=s"=>\$number_of_directions,
	"zones=s"=>\$number_of_altitudezones
) or exit(1);
#=============================================================================== 
my %fileunit;
# defaultdistanceunit
my %distanceunit;
my $error = 0;
if ($defaultdistanceunit) {
	my @defaultdistanceunit = split(/,/,$defaultdistanceunit);
	if ($defaultdistanceunit[0] =~ /^kilometer$|^nauticalmile$|^mile$|^meter$/i) {
		$distanceunit{'in'} = lc($defaultdistanceunit[0]);
		if (defined $defaultdistanceunit[1]) {
			if ($defaultdistanceunit[1] =~ /^kilometer$|^nauticalmile$|^mile$|^meter$/i) {
				$distanceunit{'out'} = lc($defaultdistanceunit[1]);
			} else {
				$error++;
			}
		} else {
			$distanceunit{'out'} = lc($defaultdistanceunit[0]);
		}
	} else {
		$error++;
	}
} else {
	$distanceunit{'in'}  = "kilometer";
	$distanceunit{'out'} = "kilometer";
}
if ($error) {
        print "The default distance unit '$defaultdistanceunit' is invalid! It should be one of these: kilometer, nauticalmile, mile or meter.\n";
        print "If you specify two units (seperated by a comma) then the first is for incomming flight position data and the second is for the range/altitude view output file.\n";
        print "for example: '-distanceunit kilometer' or '-distanceunit kilometer,nauticalmile'\n";
        exit 1;
}
# defaultaltitudeunit
my %altitudeunit;
$error = 0;
if ($defaultaltitudeunit) {
	my @defaultaltitudeunit = split(/,/,$defaultaltitudeunit);
	if ($defaultaltitudeunit[0] =~ /^meter$|^feet$/i) {
		$altitudeunit{'in'} = lc($defaultaltitudeunit[0]);
		if (defined $defaultaltitudeunit[1]) {
			if ($defaultaltitudeunit[1] =~ /^meter$|^feet$/i) {
				$altitudeunit{'out'} = lc($defaultaltitudeunit[1]);
			} else {
                		$error++;
			}
		} else {
			$altitudeunit{'out'} = lc($defaultaltitudeunit[0]);
		}
	} else {
		$error++;
	}
} else {
	$altitudeunit{'in'}  = "meter";
	$altitudeunit{'out'} = "meter";
}
if ($error) {
        print "The default altitude unit '$defaultaltitudeunit' is invalid! It should be one of these: meter or feet.\n";
        print "If you specify two units (seperated by a comma) then the first is for incomming flight position data and the second is for the range/altitude view output file.\n";
        print "for example: '-distanceunit meter' or '-distanceunit feet,meter'\n";
        exit 1; 
}
# Get correct max altitude:
my $default_max_altitude;
if ($altitudeunit{'out'} =~ /feet/) {
	$default_max_altitude = $default_max_altitude_feet;
} else {
	$default_max_altitude = $default_max_altitude_meter;
}

#
#===============================================================================
# Check options:
if ($help) {
	print "\nThis $scriptname script creates location data 
for a range/altitude view which can be displated in a modified 
fork of dump1090-mutobility.

The script creates two output files:
rangeview.csv) A file with location data in csv format can be 
   imported in to tools like http://www.gpsvisualizer.com. 
rangeview.kml) A file with location data in kml format, which
   can be imported into a modified dum1090-mutability.

Please read this post for more info:
http://discussions.flightaware.com/post180185.html#p180185

This script uses the output file(s) of the 'socket30003.pl'
script, which are by default stored in /tmp in this format:
dump1090-<hostname/ip_address>-YYMMDD.txt

It will read the files one by one and it will automaticly use 
the correct units (feet, meter, mile, nautical mile of kilometer)
for 'altitude' and 'distance' when the input files contain 
column headers with the unit type between parentheses. When 
the input files doesn't contain column headers (as produced 
by older versions of 'socket30003.pl' script) you can specify 
the units.Otherwise this script will use the default units.

The flight position data is sorted in to altitude zones. For 
each zone and for each direction the most remote location is 
saved. The most remote locations per altitude zone will be 
written to a file as a track. 

Syntax: $scriptname

Optional parameters:
	-data <data directory>		    The data files are stored in /tmp by default.
	-filemask <mask>		    Specify a filemask. 
	                                    The default filemask is 'dump*.txt'.
	-max <altitude>			    Upper limit. Default is '$default_max_altitude $altitudeunit{'out'}'. 
	                                    Higher values in the input data will be skipped.
	-min <altitude>			    Lower limit. Default is '$default_min_altitude $altitudeunit{'out'}'. 
	                                    Lower values in the input data will be skipped.
	-directions <number>		    Number of compass direction (pie slices). 
	                                    Minimal 8, maximal 7200. Default = 360.
	-zones <number>			    Number of altitude zones. Minimal 1, maximum 99. 
	                                    Default = 16.
        -lon <lonitude>                     Location of your antenna.
        -lat <latitude>                 
        -distanceunit <unit>[,<unit>]       Type of unit: kilometer, nauticalmile, mile or meter.
	                                    First unit is for the incoming source, 
	                                    the file(s) with flight positions.
                                            The second unit is for the output file. No unit 
	                                    means it is the same as incoming.
                                            Default distance unit's are: '$defaultdistanceunit'.
        -altitudeunit <unit>[,<unit>]       Type of unit: feet or meter.
                                            First unit is for the incoming source, 
	                                    the file(s) with flight positions.
                                            The second unit is for the output file. No unit 
	                                    means it is the same as incoming.
                                            Default altitude unit's are: '$defaultaltitudeunit'.
Notes: 
	- The default values can be change within the script (in the most upper section).
	- The source units will be overruled in case the input file header contains unit information.

Examples:
	$scriptname 
	$scriptname -distanceunit kilometer,nauticalmile -altitudeunit meter,feet
	$scriptname -data /home/pi\n\n";
	exit 0;
}
#=============================================================================== 
print "The altitude will be converted from '$altitudeunit{'in'}' to '$altitudeunit{'out'}'.\n";
print "The distance will be converted from '$distanceunit{'in'}' to '$distanceunit{'out'}.\n";
my %convertalt;
my %convertdis;
#===============================================================================
# Set unit for altitude and distance
sub setunits(@) {
	# altitude unit:
	$convertalt{'in'}  = 1              if ($altitudeunit{'in'}  eq "meter");
	$convertalt{'out'} = 1              if ($altitudeunit{'out'} eq "meter");
	$convertalt{'in'}  = 0.3048         if ($altitudeunit{'in'}  eq "feet");
	$convertalt{'out'} = 3.2808399      if ($altitudeunit{'out'} eq "feet");
	# altitude unit is overruled in case the input file header contains unit information:
	$convertalt{'in'}  = 1              if ((exists $fileunit{'altitude'}) && ($fileunit{'altitude'} eq "meter"));
	$convertalt{'in'}  = 0.3048	    if ((exists $fileunit{'altitude'}) && ($fileunit{'altitude'} eq "feet"));
	# distance
	$convertdis{'in'}  = 1              if ($distanceunit{'in'}  eq "meter");
	$convertdis{'out'} = 1              if ($distanceunit{'out'} eq "meter");
	$convertdis{'in'}  = 1609.344       if ($distanceunit{'in'}  eq "mile");
	$convertdis{'out'} = 0.000621371192 if ($distanceunit{'out'} eq "mile");
	$convertdis{'in'}  = 1852           if ($distanceunit{'in'}  eq "nauticalmile");
	$convertdis{'out'} = 0.000539956803 if ($distanceunit{'out'} eq "nauticalmile");
	$convertdis{'in'}  = 1000           if ($distanceunit{'in'}  eq "kilometer");
	$convertdis{'out'} = 0.001          if ($distanceunit{'out'} eq "kilometer");
	# distance unit is overruled in case the input file header contains unit information:
	$convertdis{'in'}  = 1              if ((exists $fileunit{'distance'}) && ($fileunit{'distance'} eq "meter"));
	$convertdis{'in'}  = 1609.344       if ((exists $fileunit{'distance'}) && ($fileunit{'distance'} eq "mile"));
	$convertdis{'in'}  = 1852           if ((exists $fileunit{'distance'}) && ($fileunit{'distance'} eq "nauticalmile"));
	$convertdis{'in'}  = 1000           if ((exists $fileunit{'distance'}) && ($fileunit{'distance'} eq "kilometer"));
}
setunits;
# convert altitude to the correct unit:
sub alt(@) {
	my $altitude  = shift;
	my $altitude_in_meters = $convertalt{'in'}  * $altitude;
	my $result =         int($convertalt{'out'} * $altitude_in_meters);
	return $result;
}
# convert distance to the correct unit:
sub dis(@) {
	my $distance = shift;
	my $distance_in_meters = $convertdis{'in'}  * $distance;
	my $result =         int($convertdis{'out'} * $distance_in_meters);
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
$error=0;
if ((($max) && ($max !~ /^\d+$/)) || ($max_altitude > (20000 * $convertalt{'out'})) || ($max_altitude <= $min_altitude)) {
	print "The maxium altitude ($max_altitude $altitudeunit{'out'}) is not valid! It should be at least as high as the minium altitude ($min_altitude $altitudeunit{'out'}), but not higher than ".(20000 * $convertalt{'out'})." $altitudeunit{'out'}!\n";
	$error++;
} else {
	print "The maxium altitude is $max_altitude $altitudeunit{'out'}.\n";
}
if ((($min) && ($min !~ /^\d+$/)) || ($min_altitude < 0) || ($min_altitude >= $max_altitude)) {
	print "The minium altitude ($min_altitude $altitudeunit{'out'}) is not valid! It should be less than the maximum altitude ($max_altitude $altitudeunit{'out'}), but not less than 0 $altitudeunit{'out'}!\n";
	$error++;
} else {
 	print "The minimal altitude is $min_altitude $altitudeunit{'out'}.\n";
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
$antenna_longitude =~ s/,/\./ if ($antenna_longitude);
if ($antenna_longitude !~ /^[-+]?\d+(\.\d+)?$/) {
        print "The specified longitude '$antenna_longitude' is invalid!\n";
        exit 1;
}
$antenna_latitude = $lat if ($lat);
$antenna_latitude =~ s/,/\./ if ($antenna_latitude);
if ($antenna_latitude !~ /^[-+]?\d+(\.\d+)?$/) {
        print"The specified latitude '$antenna_latitude' is invalid!\n";
        exit 1;
}
print "The latitude/longitude location of the antenna is: $antenna_latitude,$antenna_longitude.\n";
#
#===============================================================================
my $diff_altitude  = $max_altitude - $min_altitude;
$number_of_altitudezones = $number_of_altitudezones - 1;
my $zone_altitude  = int($diff_altitude / $number_of_altitudezones);
print "An altitude zone is $zone_altitude $altitudeunit{'out'}.\n";

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
	print "No files were found in '$datadirectory' that matches with the $filemask filemask!\n";
	exit 1;
} else {
        print "The following files fit with the filemask $filemask:\n";
        my @tmp;
        foreach my $file (@files) {
                chomp($file);
                next if ($file =~ /log$|pid$/i);
                print "  $file\n";
                push(@tmp,$file);
        }
        @files = @tmp;
        if (@files == 0) {
                print "No files were found in '$datadirectory' that matches with the $filemask filemask!\n";
                exit 1;
        }
}
#===============================================================================
my $filecounter=0;
my $positioncounter=0;
my %positionperzonecounter;
my %positionperdirectioncounter;
my $position;
# Read input files
foreach my $filename (@files) {
	print "processing '$filename':\n";
	$filecounter++;
	chomp($filename);
	# Read data file
	open(my $data_filehandle, '<', $filename) or die "Could not open file '$filename' $!";
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
			%fileunit =();
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
						$fileunit{$1} = $2;
						push(@unit,"$1=$2");
					} else {
						push(@header,$column);
					}
				}
				print "  -header units:".join(",",@unit).", position $linecounter";
			} else {
				# No header columns found. Use default!
				@header = ("hex_ident","altitude","latitude","longitude","date","time","angle","distance");
				print "  -default units:altitude=$altitudeunit{'in'},distance=$distanceunit{'in'}, position $linecounter";
			}
			# The file header unit information may be changed: set the units again.
			setunits;
			my $columnnumber = 0;
			# Save column name with colomn number in hash.
			foreach my $header (@header) {
			        $hdr{$header} = $columnnumber;
		        	$columnnumber++;
			}
			next if ($line =~ /hex_ident/);
		}
		# split line in to columns.
		my @col = split(/,/,$line);
		$position++;
		my $altitude = alt($col[$hdr{'altitude'}]);
		my $distance = dis($col[$hdr{'distance'}]);
		# Remove any invalid position bigger than 600km
		next if ($distance > (600000 * $convertdis{'out'}));
		# Lower then min_altitude is the lowest zone:
		$altitude = $min_altitude if ($altitude < $min_altitude);
		# Higher then max_altitude is the highest zone:
		$altitude = $max_altitude if ($altitude > $max_altitude); 
		# Calculate the altitude zone and direction zone
		my $altitude_zone  = sprintf("% 5d",int($altitude / $zone_altitude ) * $zone_altitude);
		#my $direction_zone = sprintf("% 4d",int($col[$hdr{'angle'}] * ($number_of_directions / 360)) / ($number_of_directions / 360));
		my $direction_zone = sprintf("% 4d",int($col[$hdr{'angle'}] / 360 * $number_of_directions));

		# Update the counters for statictics
		$positioncounter++;
		$positionperzonecounter{$altitude_zone} = 0 if (!exists $positionperzonecounter{$altitude_zone});
		$positionperzonecounter{$altitude_zone}++;
		$positionperdirectioncounter{$altitude_zone}{$direction_zone} = 0 if (! exists $positionperdirectioncounter{$altitude_zone}{$direction_zone});
		$positionperdirectioncounter{$altitude_zone}{$direction_zone}++;
		# Save position if it is the most fare away location for it's altitude zone and direction zoe:
		if ((!exists $data{$altitude_zone}||(!exists $data{$altitude_zone}{$direction_zone})||($data{$altitude_zone}{$direction_zone}{'distance'} < $col[$hdr{'distance'}]))) {
			$data{$altitude_zone}{$direction_zone}{'distance'}   = int($distance * 100) / 100;
                        $data{$altitude_zone}{$direction_zone}{'hex_ident'}  = $col[$hdr{'hex_ident'}];
                        $data{$altitude_zone}{$direction_zone}{'altitude'}   = int($altitude);
                        $data{$altitude_zone}{$direction_zone}{'latitude'}   = $col[$hdr{'latitude'}];
                        $data{$altitude_zone}{$direction_zone}{'longitude'}  = $col[$hdr{'longitude'}];
                        $data{$altitude_zone}{$direction_zone}{'date'}       = $col[$hdr{'date'}];
                        $data{$altitude_zone}{$direction_zone}{'time'}       = $col[$hdr{'time'}];
                        $data{$altitude_zone}{$direction_zone}{'angle'}      = int($col[$hdr{'angle'}] * 100) / 100;

		}
	}
	close($data_filehandle);
	print "-".($linecounter-1).". processed.\n";
}
print "\nNumber of files read: $filecounter\n";
print "Number of position processed: $position and positions within range processed: $positioncounter\n";
#===============================================================================
# convert hsl colors to bgr colors
sub hsl_to_bgr(@) {
    	my ($h, $s, $l) = @_;
    	my ($r, $g, $b);
    	if ($s == 0){
    		$r = $g = $b = $l;
    	} else {
   		sub hue2rgb(@){
            		my ($p, $q, $t) = @_;
            		while ($t < 0) { $t += 1;                                   }
            		while ($t > 1) { $t -= 1;                                   }
            		if ($t < 1/6)  { return $p + ($q - $p) * 6 * $t;            }
            		if ($t < 1/2)  { return $q;                                 }
            		if ($t < 2/3)  { return $p + ($q - $p) * (2/3 - $t) * 6;    }
            		return $p;
        	}
        	my $q = $l < 0.5 ? $l * (1 + $s) : $l + $s - $l * $s;
        	my $p = 2 * $l - $q;
        	$r = hue2rgb($p, $q, $h + 1/3);
        	$g = hue2rgb($p, $q, $h);
        	$b = hue2rgb($p, $q, $h - 1/3);
    	}
    	$r = sprintf("%x",int($r * 255));
	$g = sprintf("%x",int($g * 255)); 
	$b = sprintf("%x",int($b * 255));
	return $b.$g.$r;
}
#================================================================================
my @color = ("7f0000ff","7fffff00","7fff0033","7f00cc00","7fff00ff","7fff6600","7f660099","7f00ffff");
my $data_filehandle;
my $kml_filehandle;
my $trackpoint=0;
my $track=0;
my $newtrack;
print "datafile= $datadirectory/rangeview.csv\n";
print "kmlfile= $datadirectory/rangeview.kml\n";
open($data_filehandle, '>',"$datadirectory/rangeview.csv") or die "Unable to open '$datadirectory/rangeview.csv'!\n";
open($kml_filehandle, '>',"$datadirectory/rangeview.kml") or die "Unable to open '$datadirectory/rangeview.kml'!\n";
print $data_filehandle "type,new_track,name,color,trackpoint,altitudezone,destination,hex_ident,Altitude($altitudeunit{'out'}),latitude,longitude,date,time,angle,distance($distanceunit{'out'})\n";
print $kml_filehandle "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<kml xmlns=\"http://www.opengis.net/kml/2.2\">
  <Document>
    <name>Paths</name>
    <description>Example</description>\n";
foreach my $altitude_zone (sort {$a<=>$b} keys %data) {
	$track++;
        # convert altitude to feet:
        my $altitude_feet = $altitude_zone / $convertalt{'out'} * 3.2808399;
	my $s = 85;
	my $l = 50;
	my $h = 20;
	my @val = (20,140,300);
	my @alt = (2000,10000,40000);
	foreach my $index (0..$#alt) {
		if ($altitude_zone > $alt[$index]) {
			if ($index == 2) {
				$h = $val[$index];
			} else {
				$h = ($val[$index] + ($val[$index+1] - $val[$index]) * ($altitude_feet - $alt[$index]) / ($alt[$index+1] - $alt[$index]));
			}
			last;
		}
	}
	if ($h < 0) {$h = ($h % 360) + 360;} elsif ($h >= 360) {$h = $h % 360;}
        if ($s < 5) {$s = 5;} elsif ($s > 95) {$s = 95;}
        if ($l < 5) {$l = 5;} elsif ($l > 95) {$l = 95;}
	my $kml_color = "ff".hsl_to_bgr($h/360,$s/100,$l/100);
	# Determine color
	my $colornumber = $track;
	while ($colornumber > 7) {
		$colornumber = $colornumber - 8;
	}
	my $alt_zone_name = sprintf("%05d-%5d",$altitude_zone,($altitude_zone + $zone_altitude));
	my $positionperzonecounter = sprintf("% 9d",$positionperzonecounter{$altitude_zone});
	my $tracknumber = sprintf("% 2d",$track);
	$newtrack = 1;
	my $min_positions_per_direction =0;
	my $max_positions_per_direction =0;
	print $kml_filehandle "<Style id=\"track-$track\">
      <LineStyle>
        <color>$kml_color</color>
        <width>2</width>
      </LineStyle>
      <PolyStyle>
        <color>$kml_color</color>
      </PolyStyle>
    </Style>
    <Placemark>
      <name>$track</name>
      <description>$alt_zone_name</description>
      <styleUrl>#track-$track</styleUrl>
      <LineString>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>\n";
	foreach my $direction_zone (sort {$a<=>$b} keys %{$data{$altitude_zone}}) {
		my @row;
		my @kml;
		foreach my $header ("hex_ident","altitude","latitude","longitude","date","time","angle","distance") {
			push(@row,$data{$altitude_zone}{$direction_zone}{$header});
		}
		$trackpoint++;
	  	print $kml_filehandle "$data{$altitude_zone}{$direction_zone}{'longitude'},$data{$altitude_zone}{$direction_zone}{'latitude'},$data{$altitude_zone}{$direction_zone}{'altitude'}\n";	
		print $data_filehandle "T,$newtrack,Altitude zone $track: $alt_zone_name,$color[$colornumber],$trackpoint,$altitude_zone,$direction_zone,".join(",",@row)."\n";
		$newtrack = 0;
		$min_positions_per_direction = $positionperdirectioncounter{$altitude_zone}{$direction_zone} if ($positionperdirectioncounter{$altitude_zone}{$direction_zone} < $max_positions_per_direction);
		$max_positions_per_direction = $positionperdirectioncounter{$altitude_zone}{$direction_zone} if ($positionperdirectioncounter{$altitude_zone}{$direction_zone} > $max_positions_per_direction);
	}
	print $kml_filehandle "</coordinates>
      </LineString>
    </Placemark>\n";
	my $real_number_of_directions = scalar keys %{$positionperdirectioncounter{$altitude_zone}};
	my $avarage_positions_per_direction = sprintf("% 6d",($positionperzonecounter{$altitude_zone} / $number_of_directions));
	my $avarage_positions_per_real_direction =sprintf("% 6d",($positionperzonecounter{$altitude_zone} / $real_number_of_directions));
	my $line = sprintf("% 3d,Altitude zone:% 6d-% 6d,Directions:% 5d/% 5d,Positions processed:% 10d,Positions processed per direction: min:% 6d,max:% 6d,avg:% 6d,real avg:% 6d",$tracknumber,$altitude_zone,($altitude_zone + $zone_altitude-1),($real_number_of_directions+1),$number_of_directions,$positionperzonecounter{$altitude_zone},$min_positions_per_direction,$max_positions_per_direction,$avarage_positions_per_direction,$avarage_positions_per_real_direction);
	print $line."\n";
}
print $kml_filehandle "</Document>
</kml>\n";

