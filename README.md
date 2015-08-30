# dump1090.socket30003

dump1090.socket30003.pl
* Collects dump1090 flight positions using socket30003 and save them in csv format.
dump1090.socket30003.heatmap.pl
* Reads the flight positions from files in csv format and creates point for a heatmap.
dump1090.socket30003.radar.pl
* Reads the flight positions from files in csv format and creates a radar map.

0.1 version

* Help page dump1090.socket30003.pl
````
This dump1090.socket30003.pl script can retrieve flight data (lat, lon and alt) from a dump1090 host using port
30003 and calcutates the distance and angle between the antenna and the plane. It will store these 
values in a file in csv format (seperated by commas).


This script can run several times simultaneously on one host retrieving data from multiple dump1090
instances. Each instance can use the same directories, but they all have their own data, log and 
pid files.

The script can be lauched as a background process. It can be stopped by using the -stop parameter
or by removing the pid file. When it not running as a background process, it can also be stopped 
by pressing CTRL-C. The script will write the current data and log entries to the filesystem 
before exiting...

Syntax: dump1090.socket30003.pl

Optional parameters:
	-peer <peer host>		A dump1090 hostname or IP address. 
					(De default is the localhost, 127.0.0.1)
	-restart			Restart the script.
	-stop				Stop a running script.
	-status				Display status.
	-data <data directory>		The data files are stored in /tmp by default.
	-log  <log directory>		The log file is stored in /tmp by default.
	-pid  <pid directory>		The pid file is stored in /tmp by default.
	-msgmargin <max message margin> The max message margin is 10ms by default.
	-lon <lonitude>			Location of your antenna.
	-lat <latitude>			
	-help				This help page.

Notes: 
- To launch it as a background process, add '&'.
- The default values can be change within the script (in the most upper section).


Examples:
	dump1090.socket30003.pl 
	dump1090.socket30003.pl -log /var/log -data /home/pi -pid /var/run -restart &
	dump1090.socket30003.pl -peer 192.168.1.10 -stop

Pay attention: to stop an instance: Don't forget to specify the same peer host.
````
# Output dump1090.socket30003.pl
* Default outputfile: /tmp/dump1090.socket30003.pl-192_168_11_34-150830.txt (dump1090.socket30003.pl-<IP-ADDRESS-PEER>-<date>.txt)
````
header: hex_ident,altitude(feet),latitude,longitude,date,time,direction,distance(meter)
data:
4010DB,35000,52.31159,5.65019,2015/08/30,17:48:55.481,67.1801766700598,45756.6730179409
400A60,37000,50.78618,4.92173,2015/08/30,17:48:55.483,-172.94938714767,144949.287631512
478533,37000,51.55232,3.72444,2015/08/30,17:48:55.524,-112.113114036685,110962.328386504
4841DB,4425,52.13664,4.44099,2015/08/30,17:48:55.527,-85.2749293488927,44615.3540134401
400B44,33000,51.99193,4.97032,2015/08/30,17:48:55.540,-129.457164021526,13209.2852899247
400E14,38000,52.11044,5.48210,2015/08/30,17:48:55.547,86.2130260390998,26988.0996886073
478538,37000,52.77310,5.54024,2015/08/30,17:48:55.583,32.1346191471548,82332.7806446534
4CA9B4,26900,51.54399,5.28992,2015/08/30,17:48:55.603,160.416360285161,61786.3690908337
478535,37000,51.88899,5.57732,2015/08/30,17:48:55.631,112.766312936825,39947.5126386791
4249BD,3725,52.19934,4.85542,2015/08/30,17:48:55.647,-63.0644110287155,20348.0966975414
````
# Help page dump1090.socket30003.heatmap.pl
````
This dump1090.socket30003.heatmap.pl script can create heatmap data

Syntax: dump1090.socket30003.heatmap.pl

Optional parameters:
	-data <data directory>		The data files are stored in /tmp by default.
	-filemask <mask>		Specify a filemask. The default filemask is 'dump.socket*.txt'.
	-help				This help page.

Examples:
	dump1090.socket30003.heatmap.pl 
	dump1090.socket30003.heatmap.pl -data /home/pi
````
# Output dump1090.socket30003.heatmap.pl
* Default output file: /tmp/heatmap.csv
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
# Help page dump1090.socket30003.radar.pl
````
This dump1090.socket30003.radar.pl script can sort flight data (lat, lon and alt).

Syntax: dump1090.socket30003.radar.pl

Optional parameters:
	-data <data directory>		The data files are stored in /tmp by default.
	-filemask <mask>		Specify a filemask. The default filemask is 'dump.socket*.txt'.
	-max <altitude>			Upper limit. Default is 48000. Higher values in the input data will be skipped.
	-min <altitude>			Lower limit. Default is 0. Lower values in the input data will be skipped.
	-directions <number>		Number of compass direction (pie slices). Minimal 8, maximal 7200. Default = 360.
	-zones <number>			Number of altitude zones. Minimal 1, maximum 99. Default = 16.
        -lon <lonitude>                 Location of your antenna.
        -lat <latitude>    
	-help				This help page.             

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
