# dump1090.socket30003

dump1090.socket30003.pl
* Collects dump1090 flight positions using socket30003 and save them in csv format.
dump1090.socket30003.heatmap.pl
* Reads the flight positions from files in csv format and creates point for a heatmap.
dump1090.socket30003.radar.pl
* Reads the flight positions from files in csv format and creates a radar map.

0.1 version / 2015-09-01 / Ted Sluis

# Help page dump1090.socket30003.pl
````
This dump1090.socket30003.pl script can retrieve flight data (lat, lon and alt) from a dump1090 host using port
30003 and calcutates the distance and angle between the antenna and the plane. It will store these 
values in a file in csv format (seperated by commas).


This script can run several times simultaneously on one host retrieving data from multiple dump1090
instances. Each instance can use the same directories, but they all have their own data, log and 
pid files.

The script can be lauched as a background process. It can be stopped by using the -stop parameter
or by removing the pid file. When running from commandline it can also be stopped 
by pressing CTRL-C. The script will write the current data and log entries to the filesystem 
before exiting...

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
	-msgmargin <max message margin> The max message margin is 10ms by default.
	-lon <lonitude>                 Location of your antenna.
	-lat <latitude>			
	-distancematric <matric>        Type of matric: kilometer, nauticalmile, mile or meter
	                                Default distance matric is kilometer.
	-altitudematric <matric>        Type of matric: meter or feet.
	                                Default altitude matric is meter.
	-nopositions                    Does not display the number of position when running
	                                interactive (launched from commandline).
	-help                           This help page.

Notes: 
- To launch it as a background process, add '&' or run it from crontab:
  0 * * * * <path>/dump1090.socket30003.pl
  (This command checks if it ran every hour and relauch it if nessesary.)
- The default values can be change within the script (in the most upper section).
- When launched from the commandline it will display the number of positions.

Examples:
	dump1090.socket30003.pl 
	dump1090.socket30003.pl -peer 192.168.1.10 -nopositions -distancematric nauticalmile -altitudematric feet &
	dump1090.socket30003.pl -log /var/log -data /home/pi -pid /var/run -restart 
	dump1090.socket30003.pl -peer 192.168.1.10 -stop

Pay attention: when stopping an instance: Don't forget to specify correct the peer host.
````
# Output dump1090.socket30003.pl
* Default outputfile: /tmp/dump1090.socket30003.pl-192_168_11_34-150830.txt (dump1090.socket30003.pl-<IP-ADDRESS-PEER>-<date>.txt)
````
header: hex_ident,altitude,latitude,longitude,date,time,direction,distance
data:
3950C5,11880,52.64197,6.73431,2015/09/01,22:07:56.555,70.48,127.68
343695,807,52.25015,5.05760,2015/09/01,22:07:56.573,-10.38,18.41
406BBB,11057,50.92037,3.85033,2015/09/01,22:07:56.620,-134.38,155.35
400EFC,3670,52.61050,4.48329,2015/09/01,22:07:56.635,-47.84,71.4
8990DD,8224,52.04086,6.79138,2015/09/01,22:07:56.673,91.49,116.47
A333B5,10669,52.04095,3.36670,2015/09/01,22:07:56.682,-91.47,117.83
3C6446,11567,51.60269,5.99185,2015/09/01,22:07:56.683,119.11,82.03
4CA355,11880,53.39719,4.48832,2015/09/01,22:07:56.689,-23.65,151.33
3C6605,11270,50.72575,4.55933,2015/09/01,22:07:56.691,-159.48,155.6
71BF21,4363,52.71680,5.26703,2015/09/01,22:07:56.698,15.1,71.21
4CA212,5909,51.19363,3.38015,2015/09/01,22:07:56.700,-118.47,154.07
4CA257,11270,50.63464,5.00360,2015/09/01,22:07:56.719,-176.76,161.44
471F5F,11811,52.38455,3.05183,2015/09/01,22:07:56.729,-81.2,142.64
4CA27F,10966,52.59970,3.66833,2015/09/01,22:07:56.746,-69.24,112.16
````
# Help page dump1090.socket30003.heatmap.pl
````
This dump1090.socket30003.heatmap.pl script can create heatmap data.
At this moment it only creates a file with java script code, which
must be add to the script.js manualy in order to get a heatmap layer.
Please read this post for more info:
http://discussions.flightaware.com/ads-b-flight-tracking-f21/heatmap-for-dump1090-mutability-t35844.html

Syntax: dump1090.socket30003.heatmap.pl

Optional parameters:
	-data <data directory>          The data files are stored in /tmp by default.
	-filemask <mask>                Specify a filemask. The default filemask is 'dump.socket*.txt'.
        -lon <lonitude>                 Location of your antenna.
        -lat <latitude>
	-maxpositions <max positions>   Default is 100000 positions.
	-resolution <number>            Number of horizontal and vertical positions in output heatmap file.
	                                Default is 1000, which means 1000x1000 positions.
	-degrees <number>               To determine boundaries of area around the antenna.
	                                (lat-degree -- lat+degree) x (lon-degree -- lon+degree)
	                                De default is 3 degree.
	-help                           This help page.

note: 
	The default values can be changed within the script (in the most upper section).


Examples:
	dump1090.socket30003.heatmap.pl 
	dump1090.socket30003.heatmap.pl -data /home/pi
	dump1090.socket30003.heatmap.pl -lat 52.1 -lon 4.1 -maxposition 50000
````
# Output dump1090.socket30003.heatmap.pl
* Default output file: /tmp/heatmap.csv
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
# Help page dump1090.socket30003.radar.pl
````
This dump1090.socket30003.radar.pl script can sort flight data (lat, lon and alt).

Syntax: dump1090.socket30003.radar.pl

Optional parameters:
	-data <data directory>          The data files are stored in /tmp by default.
	-filemask <mask>                Specify a filemask. The default filemask is 'dump.socket*.txt'.
	-max <altitude>                 Upper limit. Default is 48000. Higher values in the input data will be skipped.
	-min <altitude>                 Lower limit. Default is 0. Lower values in the input data will be skipped.
	-directions <number>            Number of compass direction (pie slices). Minimal 8, maximal 7200. Default = 360.
	-zones <number>                 Number of altitude zones. Minimal 1, maximum 99. Default = 16.
	-lon <lonitude>                 Location of your antenna.
	-lat <latitude>    
	-help                           This help page.             

Notes: 
- To launch it as a background process, add '&'.
- The default values can be change within the script.

Examples:
	dump1090.socket30003.radar.pl 
	dump1090.socket30003.radar.pl -data /home/pi
````
# Output dump1090.socket30003.radar.pl
* Default output file: /tmp/radar.csv
````
type,new_track,name,color,trackpoint,altitudezone,destination,hex_ident,Altitude,latitude,longitude,date,time,angle,distance
T,1,Altitude zone 1: 00000- 3000,yellow,1,    0,-143,44D991,1825,51.18549,4.40218,2015/08/17,14:50:34.875,-143.768514490891,110742.048628643
T,0,Altitude zone 1: 00000- 3000,yellow,2,    0,-142,44D991,2675,51.18709,4.36372,2015/08/17,14:50:08.608,-142.218127849853,111744.222386486
T,0,Altitude zone 1: 00000- 3000,yellow,3,    0,-131,484BCE,1900,51.61959,4.54590,2015/08/17,09:12:40.772,-131.800165083269,63848.8835462889
T,0,Altitude zone 1: 00000- 3000,yellow,4,    0,-115,484BCD,1900,51.83739,4.54752,2015/08/17,14:22:53.568,-115.531263666627,46243.1709127753
T,0,Altitude zone 1: 00000- 3000,yellow,5,    0,-114,44049F,2850,51.86472,4.59243,2015/08/17,23:48:20.523,-114.869577276237,41956.5893649617
T,0,Altitude zone 1: 00000- 3000,yellow,6,    0,-113,484BCD,1925,51.87749,4.59830,2015/08/17,14:20:59.489,-113.843637113441,40805.7445058548
T,0,Altitude zone 1: 00000- 3000,yellow,7,    0,-112,484BCD,1925,51.86591,4.53721,2015/08/17,14:23:51.021,-112.529875618193,45004.9231205215
T,0,Altitude zone 1: 00000- 3000,yellow,8,    0,-111,44D991,2050,51.12048,2.48551,2015/08/17,14:33:01.602,-111.012812371387,209373.761058365
T,0,Altitude zone 1: 00000- 3000,yellow,9,    0,-110,44D991,2650,51.11998,2.47987,2015/08/17,14:32:58.166,-110.980857750807,209737.525203623
````
