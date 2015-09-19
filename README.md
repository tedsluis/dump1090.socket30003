# dump1090.socket30003

dump1090.socket30003.pl
* Collects dump1090 flight positions (ADB-S format) using socket 30003 and save them in csv format.

dump1090.socket30003.heatmap.pl
* Reads the flight positions from files in csv format and creates points for a heatmap.
* The heatmap shows where planes come very often. It makes common routes visable.
* Output in csv format and locations in javascript code.

dump1090.socket30003.radar.pl
* Reads the flight positions from files in csv format and creates a radar view map. 
* The radar view shows the maximum range of your antenna for every altitude zone.
* Add KML output support.

The output heatmapdata.csv and radarview.kml can be displayed in a modified variant of dump1090-mutability.

0.1 version / 2015-09-19 / Ted Sluis

Read more about this at:
http://discussions.flightaware.com/topic35844.html

# Help page dump1090.socket30003.pl
````
This dump1090.socket30003.pl script can retrieve flight data (lat, lon and alt) from
a dump1090 host using port 30003 and calcutates the distance and angle
between the antenna and the plane. It will store these values in an 
output file in csv format (seperated by commas).

This script can run several times simultaneously on one host retrieving
data from multiple dump1090 instances. Each instance can use the same 
directories, but they all have their own data, log and pid files. And 
every day the script will create a new data and log file.

A data files contain column headers (with the names of the columns). 
Columns headers like 'altitude' and 'distance' also contain their unit
between parentheses, for example '3520(feet)' or '12,3(kilometer)'. This
makes it more easy to parse the columns when using this data in other
scripts. Every time the script is (re)started a header wiil be written 
in to the data file. This way it is possible to switch a unit, for 
example from 'meter' to 'kilometer', and other scripts will still be able
to determine the correct unit type.

The script can be lauched as a background process. It can be stopped by
using the -stop parameter or by removing the pid file. When it not 
running as a background process, it can also be stopped by pressing 
CTRL-C. The script will write the current data and log entries to the 
filesystem before exiting...

Syntax: dump1090.socket30003.pl

Optional parameters:
	-peer <peer host>               A dump1090 hostname or IP address. 
	                                (De default is the localhost, 127.0.0.1)
	-restart                        Restart the script.
	-stop                           Stop a running script.
	-status                         Display status.
	-data <data directory>          The data files are stored in /tmp by default.
	-log  <log directory>           The log file is stored in /tmp by default.
	-pid  <pid directory>           The pid file is stored in /tmp by default.
	-msgmargin <max message margin> The max message margin. The default is 10ms.
	-lon <lonitude>                 Location of your antenna.
	-lat <latitude>			
	-distanceunit <unit>            Type of unit: kilometer, nauticalmile, mile or meter.
	                                Default distance unit is kilometer.
	-altitudeunit <unit>            Type of unit: meter or feet.
	                                Default altitude unit is meter.
	-nopositions                    Does not display the number of position when running.
	                                interactive (launched from commandline).
	-help                           This help page.

Notes: 
- To launch it as a background process, add '&' or run it from crontab:
  0 * * * * <path>/dump1090.socket30003.pl
  (This command checks if it ran every hour and relauch it if nessesary.)
- The default values can be changed within the script (in the most upper section).
- When launched from the commandline it will display the number of positions.

Examples:
	dump1090.socket30003.pl 
	dump1090.socket30003.pl -peer 192.168.1.10 -nopositions -distanceunit nauticalmile -altitudeunit feet &
	dump1090.socket30003.pl -log /var/log -data /home/pi -pid /var/run -restart 
	dump1090.socket30003.pl -peer 192.168.1.10 -stop

Pay attention: when stopping an instance: Don't forget to specify correct the peer host.
````
# Output dump1090.socket30003.pl
* Default outputfile: /tmp/dump1090.socket30003.pl-192_168_11_34-150830.txt (dump1090.socket30003.pl-<IP-ADDRESS-PEER>-<date>.txt)
````
hex_ident,altitude(meter),latitude,longitude,date,time,angle,distance(kilometer)
4CA766,11575,51.67790,2.85407,2015/09/05,08:30:23.010,-100.67,159.95
45C261,10966,51.82130,5.17868,2015/09/05,08:30:23.041,161.99,30.02
424050,10357,52.33214,4.21715,2015/09/05,08:30:23.050,-73.52,65.42
401240,10973,52.27798,3.94598,2015/09/05,08:30:23.079,-79.98,80.81
3950D1,6998,51.75334,4.62910,2015/09/05,08:30:23.091,-126.97,48.57
4841A6,1523,52.43298,5.31036,2015/09/05,08:30:23.092,31.39,41.45
342105,7447,51.35345,4.22089,2015/09/05,08:30:23.120,-131.28,101.01
hex_ident,altitude(feet),latitude,longitude,date,time,angle,distance(meter)
484443,12125,52.24008,3.99765,2015/09/05,12:54:14.926,-81.54,76395
48415E,4175,52.31666,5.17440,2015/09/05,12:54:14.932,19.48,26338
300092,3550,52.22533,4.70748,2015/09/05,12:54:14.933,-69.07,30312
3C6DD4,25975,50.77332,5.39941,2015/09/05,12:54:14.934,167.2,147491
4CA854,38000,51.80789,5.20393,2015/09/05,12:54:14.977,158.36,31868
484C5A,16375,51.80800,4.67743,2015/09/05,12:54:14.980,-125.1,41818
````
note: As you can see it is possible to switch over to different type units for 'altitude' and 'distance'!

# Help page dump1090.socket30003.heatmap.pl
````
This dump1090.socket30003.heatmap.pl script creates heatmap data 
which can be displated in a modified variant of dump1090-mutobility.

It creates two output files:
1) One file with locations in java script code, which must be added
   to the script.js manualy.
2) One file with location data in csv format, which can be imported
   from the dump1090 GUI.

Please read this post for more info:
http://discussions.flightaware.com/ads-b-flight-tracking-f21/heatmap-for-dump1090-mutability-t35844.html

This script uses the output file(s) of the 'dump1090.socket30003.pl'
script. It will automaticly use the correct units (feet, meter, 
kilometer, mile, natical mile)  for 'altitude' and 'distance' when 
the input files contain column headers with the unit type between 
parentheses. When the input files doesn't contain column headers 
(as produced by older versions of 'dump1090.socket30003.pl' script)
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


Syntax: dump1090.socket30003.heatmap.pl

Optional parameters:
	-data <data directory>          The data files are stored
	                                 in /tmp by default.
	-filemask <mask>                Specify a filemask. The 
	                                default filemask is 'dump*.txt'.
	-lon <lonitude>                 Location of your antenna.
	-lat <latitude>
	-maxpositions <max positions>   Default is 100000 positions.
	-maxweight <number>             Maximum position weight on 
	                                the heatmap. The default is 1000.
	-resolution <number>            Number of horizontal and vertical
	                                positions in output heatmap file.
	                                Default is 1000, which 
	                                means 1000x1000 positions.
	-degrees <number>               To determine boundaries of 
	                                area around the antenna.
	                                (lat-degree <--> lat+degree) x
	                                (lon-degree <--> lon+degree)
	                                De default is 5 degree.
	-help                           This help page.

note: 
	The default values can be changed within the script 
	(in the most upper section).


Examples:
	dump1090.socket30003.heatmap.pl 
	dump1090.socket30003.heatmap.pl -data /home/pi
	dump1090.socket30003.heatmap.pl -lat 52.1 -lon 4.1 -maxposition 50000
````
# Output dump1090.socket30003.heatmap.pl
* Default output file: /tmp/heatmapcode.csv
````
{location: new google.maps.LatLng(51.025, 3.1), weight: 706},
{location: new google.maps.LatLng(50.925, 4.4), weight: 706},
{location: new google.maps.LatLng(50.837, 4.775), weight: 706},
{location: new google.maps.LatLng(50.75, 4.612), weight: 706},
{location: new google.maps.LatLng(50.7, 4.562), weight: 706},
{location: new google.maps.LatLng(52.837, 5.475), weight: 705},
{location: new google.maps.LatLng(52.537, 4.025), weight: 705},
{location: new google.maps.LatLng(52.512, 5.75), weight: 705},
{location: new google.maps.LatLng(52.437, 3.662), weight: 705},
{location: new google.maps.LatLng(52.362, 6.2), weight: 705},
{location: new google.maps.LatLng(52.35, 5.5), weight: 705},
````
* Default output file: /tmp/heatmapdata.csv
````
"weight";"lat";"lon"
"1000";"52.397";"4.721"
"919";"52.389";"4.721"
"841";"52.405";"4.721"
"753";"52.413";"4.721"
"750";"52.517";"5.297"
"743";"52.317";"5.177"
"679";"51.925";"2.849"
"641";"51.853";"6.065"
"609";"51.229";"3.649"
````
# Help page dump1090.socket30003.radar.pl
````
This dump1090.socket30003.radar.pl script create location data 
for a radar view which can be displated in a modified variant 
of dump1090-mutobility.

It creates two output files:
1) One file with location dat in csv format can be imported
   in to tools like http://www.gpsvisualizer.com. 
2) One file with location data in kml format, which can be 
   imported into a modified dum1090-mutability variant.

Please read this post for more info:
http://discussions.flightaware.com/ads-b-flight-tracking-f21/heatmap-for-dump1090-mutability-t35844.html

This script uses the output file(s) of the 
'dump1090.socket30003.pl' script. It will automaticly use the
correct units (feet, meter, mile, nautical mile of kilometer)
for 'altitude' and 'distance' when the input files contain 
column headers with the unit type between parentheses. When 
the input files doesn't contain column headers (as produced 
by older versions of 'dump1090.socket30003.pl' script) you 
can specify the units.Otherwise this script will use the 
default units.

The flight position data is sorted in to altitude zones. For 
each zone and for each direction the most remote location is 
saved. The most remote locations per altitude zone will be 
written to a file as a track. 


Syntax: dump1090.socket30003.radar.pl

Optional parameters:
	-data <data directory>          The data files are stored 
	                                in /tmp by default.
	-filemask <mask>                Specify a filemask. The 
	                                default filemask is 'dump.socket*.txt'.
	-max <altitude>                 Upper limit. Default is 48000. 
	                                Higher values in the input 
	                                data will be skipped.
	-min <altitude>                 Lower limit. Default is 0. 
	                                Lower values in the 
	                                input data will be skipped.
	-directions <number>            Number of compass direction (pie slices). 
	                                Minimal 8, maximal 7200. 
	                                Default = 360.
	-zones <number>                 Number of altitude zones. 
	                                Minimal 1, maximum 99. 
	                                Default = 16.
	-lon <lonitude>                 Location of your antenna.
	-lat <latitude>    
	-distanceunit <unit>[,<unit>]   Type of unit: kilometer,
	                                nauticalmile, mile or meter.
	                                First unit is for the incoming
	                                source, the file(s) with flight positions.
	                                The second unit is for the output file. 
	                                No unit means it is the same as incoming.
	                                Default distance unit's are: 'kilometer,kilometer'.
	-altitudeunit <unit>[,<unit>]   Type of unit: feet or meter.
	                                First unit is for the incoming
	                                source, the file(s) with flight positions.
	                                The second unit is for the output file. 
	                                No unit means it is the same as incoming.
	                                Default altitude unit's are: 'meter,meter'.
	-help                           This help page.             

Notes: 
- To launch it as a background process, add '&'.
- The default values can be changed within the script.

Examples:
	dump1090.socket30003.radar.pl 
	dump1090.socket30003.radar.pl -distanceunit kilometer,nauticalmile -altitudeunit meter,feet
	dump1090.socket30003.radar.pl -data /home/pi
````
# Output dump1090.socket30003.radar.pl
* Default output file: /tmp/radar.csv
````
type,new_track,name,color,trackpoint,altitudezone,destination,hex_ident,Altitude(meter),latitude,longitude,date,time,angle,distance(kilometer)
T,1,Altitude zone 1: 00000- 1000,yellow,1,    0,-575,484575,900,52.08119,5.08568,2015/08/19,15:58:15.725,-143.85,544
T,0,Altitude zone 1: 00000- 1000,yellow,2,    0,-487,484E0A,825,52.08202,5.08301,2015/08/21,12:20:01.072,-121.86,575
T,0,Altitude zone 1: 00000- 1000,yellow,3,    0,-485,484AEE,950,52.08199,5.08282,2015/08/21,12:53:41.929,-121.28,587
T,0,Altitude zone 1: 00000- 1000,yellow,4,    0,-483,484AEE,950,52.08202,5.08278,2015/08/21,12:53:41.928,-120.91,587
T,0,Altitude zone 1: 00000- 1000,yellow,5,    0,-469,484E0A,825,52.08311,5.08400,2015/08/21,12:19:57.468,-117.4,444
T,0,Altitude zone 1: 00000- 1000,yellow,6,    0,-422,484E0A,825,52.08472,5.08568,2015/08/21,12:19:52.334,-105.59,251
T,0,Altitude zone 1: 00000- 1000,yellow,7,    0,-412,4841D6,997,51.92171,4.35223,2015/09/04,16:56:45.997,-103.03,53
T,0,Altitude zone 1: 00000- 1000,yellow,8,    0,-411,4841D6,967,51.92297,4.35482,2015/09/04,16:56:43.536,-102.97,53
T,0,Altitude zone 1: 00000- 1000,yellow,9,    0,-410,4841D6,761,51.93031,4.37363,2015/09/04,16:56:28.453,-102.72,51
````

* Default output file: /tmp/radar.kml
````
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Paths</name>
    <description>Example</description>
<Style id="track-1">
      <LineStyle>
        <color>ff135beb</color>
        <width>2</width>
      </LineStyle>
      <PolyStyle>
        <color>ff135beb</color>
      </PolyStyle>
    </Style>
    <Placemark>
      <name>1</name>
      <description>00000- 1000</description>
      <styleUrl>#track-1</styleUrl>
      <LineString>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>
5.08867,51.44989,883
5.08578,51.40952,975
5.08288,51.41190,960
5.07279,51.02161,876
5.07472,51.42160,922
5.07301,51.42279,922
5.07093,51.46349,883
5.06588,51.43039,891
etc..
````

