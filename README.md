# dump1090.socket30003

## Table of contents

   * [dump1090.socket30003](#dump1090socket30003)
      * [Collect flight data for heatmap and rangview](#collect-flight-data-for-heatmap-and-rangview)
      * [Screenshots and video](#screenshots-and-video)
      * [The scripts](#the-scripts)
      * [Help page socket30003.pl](#help-page-socket30003pl)
         * [Output socket30003.pl](#output-socket30003pl)
      * [Help page heatmap.pl](#help-page-heatmappl)
         * [Output heatmap.pl](#output-heatmappl)
      * [Help page rangeview.pl](#help-page-rangeviewpl)
         * [Output rangeview.pl](#output-rangeviewpl)
      * [Help page install.pl](#help-page-installpl)
      * [Installation](#installation)
         * [Clone this repo](#clone-this-repo)
         * [Edit config file](#edit-config-file)
         * [Run installer](#run-installer)
         * [Add socket30003.pl as a crontab job](#add-socket30003pl-as-a-crontab-job)
         * [Check the log and output file](#check-the-log-and-output-file)
         * [Run heatmap.pl](#run-heatmappl)
         * [Run rangview.pl](#run-rangviewpl)
         * [View the heatmap](#view-the-heatmap)
         * [View the rangeview](#view-the-rangeview)
      * [More info](#more-info)

## Collect flight data for heatmap and rangview
  
Use your dump1090 to collect flight data and create a heatmap and rangeview.
   
## Screenshots and video

Heatmap
[![Dump1090 Heatmap](https://raw.githubusercontent.com/tedsluis/dump1090.socket30003/master/img/heatmap-example1.png)](https://raw.githubusercontent.com/tedsluis/dump1090.socket30003/master/img/heatmap-example1.png)

Rangeview
[![Dump1090 rangeview](https://raw.githubusercontent.com/tedsluis/dump1090.socket30003/master/img/rangeview-example1.png)](https://raw.githubusercontent.com/tedsluis/dump1090.socket30003/master/img/rangeview-example1.png)

Youtube video:
[![Dump1090 rangeview](https://raw.githubusercontent.com/tedsluis/dump1090/master/img/youtube16.png)](https://www.youtube.com/watch?v=Qz4XSFRjLTI)

## The scripts
  
socket30003.pl
* Collects dump1090 flight positions (ADB-S format) using a tcp socket 30003 stream   
  and save them in csv format.

heatmap.pl
* Reads the flight positions from files in csv format and creates points for a heatmap.
* The heatmap shows where planes come very often. It makes common routes visable.
* Output in csv format (Google maps format).

rangeview.pl
* Reads the flight positions from files in csv format and creates a range/altitude view map. 
* The range/altitude view shows the maximum range of your antenna for every altitude zone.
* KML output support (Google maps format).

install.pl
* Simpel installer script.

socket30003.cfg
* config file for socket30003.pl, heatmap.pl, rangeview.pl and install.pl

The output heatmapdata.csv and rangeview.kml can be displayed in a my modified variant 
of dump1090-mutability: https://github.com/tedsluis/dump1090

Read more about this at:
http://discussions.flightaware.com/topic35844.html

## Help page socket30003.pl
````
This socket30003.pl script can retrieve flight data (like lat, lon and alt) 
from a dump1090 host using port 30003 and calcutates the distance and 
angle between the antenna and the plane. It will store these values in an 
output file in csv format (seperated by commas) together with other flight
data.

This script can run several times simultaneously on one host retrieving
data from multiple dump1090 instances on different hosts. Each instance 
can use the same directories, but they all have their own data, log and 
pid files. And every day the script will create a new data and log file.

A data files contain column headers (with the names of the columns). 
Columns headers like 'altitude', 'distance' and 'ground_speed' also contain
their unit between parentheses, for example '3520(feet)' or '12,3(kilometer)'.
This makes it more easy to parse the columns when using this data in other
scripts. Every time the script is (re)started a header wiil be written 
in to the data file. This way it is possible to switch a unit, for 
example from 'meter' to 'kilometer', and other scripts will still be able
to determine the correct unit type.

By default the position data, log files and pid file(s) will be stored in this format:
  dump1090-<hostname/ip_address>-<YYMMDD>.txt
  dump1090-<hostname/ip_address>-<YYMMDD>.log
  dump1090-<hostname/ip_address>.pid

The script can be lauched as a background process. It can be stopped by
using the -stop parameter or by removing the pid file. When it not 
running as a background process, it can also be stopped by pressing 
CTRL-C. The script will write the current data and log entries to the 
filesystem before exiting...

More info at:
http://discussions.flightaware.com/post180185.html#p180185

Syntax: socket30003.pl

Optional parameters:
        -peer <peer host>               A dump1090 hostname or IP address. 
                                        De default is the localhost, 127.0.0.1.
        -restart                        Restart the script.
        -stop                           Stop a running script.
        -status                         Display status.
        -data <data directory>          The data files are stored in /tmp by default.
        -log  <log directory>           The log file is stored in /tmp by default.
        -pid  <pid directory>           The pid file is stored in /tmp by default.
        -msgmargin <max message margin> The max message margin. The default is 10 ms.
        -lon <lonitude>                 Location of your antenna.
        -lat <latitude>
        -distanceunit <unit>            Type of unit for distance: kilometer, 
                                        nauticalmile, mile or meter
                                        Default distance unit is kilometer.
        -altitudeunit <unit>            Type of unit for altitude: meter or feet.
                                        Default altitude unit is meter.
        -speedunit <unit>               Type of unit for ground speed.
                                        Default speed unit is kilometerph.
        -nopositions                    Does not display the number of position while
                                        running interactive (launched from commandline).
        -debug                          Displays raw socket messages.
        -verbose                        Displays verbose log messages.
        -help                           This help page.

Notes: 
        - To launch it as a background process, add '&' or run it from crontab:
          0 * * * * /home/tedsluis/git/dump1090.socket30003/socket30003.pl
          (This command checks if it ran every hour and relauch it if nessesary.)
        - The default values can be changed within the config file 'socket30003.cfg',
          section [common] and/or [socket30003].
  
Examples:
        socket30003.pl 
        socket30003.pl -log /var/log -data /home/pi -pid /var/run -restart &
        socket30003.pl -peer 192.168.1.10 -nopositions -distanceunit nauticalmile -altitudeunit feet &
        socket30003.pl -peer 192.168.1.10 -stop

Pay attention: to stop an instance: Don't forget to specify the same peer host.
````
### Output socket30003.pl
* Default outputfile: /tmp/dump1090-192_168_11_34-150830.txt (dump1090-<IP-ADDRESS-PEER>-<date>.txt)
````
hex_ident,altitude(meter),latitude,longitude,date,time,angle,distance(kilometer),squawk,ground_speed(kilometerph),track,callsign
484CB8,3906,52.24399,5.25500,2017/01/09,16:35:02.113,45.11,20.93,0141,659,93,KLM1833 
406D77,11575,51.09984,7.73237,2017/01/09,16:35:02.129,111.12,212.94,,,,BAW256  
4CA1D4,11270,53.11666,6.02148,2017/01/09,16:35:03.464,40.85,130.79,,842,81,RYR89VN 
4B1A1B,3426,51.86971,4.14556,2017/01/09,16:35:03.489,-103.38,68.93,1000,548,352,EZS85TP 
4CA79D,11575,51.95681,4.17119,2017/01/09,16:35:03.489,-98.28,64.41,1366,775,263,RYR43FH 
hex_ident,altitude(feet),latitude,longitude,date,time,angle,distance(mile),squawk,ground_speed(mileph),track,callsign
48500,1416,52.53923,4.95834,2017/01/09,16:41:40.885,-15.42,51.21,1000,377,279,TRA5802 
478690,11141,50.66931,3.43764,2017/01/09,16:41:40.886,-131.71,194.76,5325,542,37,SAS22K  
34260E,10966,51.77884,5.07965,2017/01/09,16:41:40.888,-178.31,34.11,1114,522,214,IBE32HP 
484558,5071,52.48020,4.22715,2017/01/09,16:41:40.892,-64.42,73.22,6260,459,303,KLM55U  
4951B7,11270,52.78214,2.43583,2017/01/09,16:41:40.901,-74.55,195.81,2375,442,40,TAP766  
````
note: As you can see it is possible to switch over to different type units for 'altitude', 'distance' and 'ground speed'!

## Help page heatmap.pl
````
This heatmap.pl script creates heatmap data 
which can be displated in a modified variant of dump1090-mutobility.

It creates an output file with location data in csv format, which can 
be imported using the dump1090 GUI.

Please read this post for more info:
http://discussions.flightaware.com/post180185.html#p180185

This script uses the data file(s) created by the 'socket30003.pl'
script, which are by default stored in '/tmp' in this format:
dump1090-<hostname/ip_address>-YYMMDD.txt

The script will automaticly use the correct units (feet, meter, 
kilometer, mile, natical mile) for 'altitude' and 'distance' when 
the input files contain column headers with the unit type between 
parentheses. When the input files doesn't contain column headers 
(as produced by older versions of 'socket30003.pl' script)
you can specify the units using startup parameters or in the config
file. Otherwise this script will use the default units.

This script will create a heatmap of a square area around your 
antenna. You can change the default range by specifing the number
of degrees -/+ to your antenna locations. (The default values will
probably satisfy.) This area will be devided in to small squares. 
The default heatmap has a resolution of 1000 x 1000 squares. 
The script will read all the flight position data from the source
file(s) and count the times they match with a square on the heatmap. 

The more positions match with a particular square on the heatmap, 
the more the 'weight' that heatmap position gets. We use only the 
squares with the most matches (most 'weight) to create the heatmap.
This is because the map in the browser gets to slow when you use 
too much positions in the heatmap. Of cource this also depends on 
the amount of memory of your system. You can change the default 
number of heatmap positions. You can also set the maximum of 
'weight' per heatmap position. 

Syntax: heatmap.pl

Optional parameters:
  -data <data directory>  The data files are stored in
                          '/tmp' by default.
  -log <log directory>    The data files are stored in 
                          '/tmp' by default.
  -output <output         The data files are stored in 
          directory>      '/tmp' by default.
  -file <filename>        The output file name. 
                          'heatmapdata.csv' by default.
  -filemask <mask>        Specify a filemask for the source data. 
                          The default filemask is 'dump*.txt'.
  -override               Override output file if exists. 
                          Default is 'no'.
  -timestamp              Add timestamp to output file name. 
                          Default is 'no'.
  -sequencenumber         Add sequence number to output file name. 
                          Default is 'no'.
  -lon <lonitude>         Location of your antenna.
  -lat <latitude>
  -maxpositions <max      Maximum spots in the heatmap. Default is
             positions>   '100000' positions.
  -maxweight <number>     Maximum position weight. The default is 
                          '1000'.
  -resolution <number>    Number of horizontal and vertical positions
                          in output file. Default is '1000', 
                          which means '1000x1000' positions.
  -degrees <number>       To determine boundaries of area around the
                          antenna. (lat-degree <--> lat+degree) x 
                          (lon-degree <--> lon+degree)
                          De default is '5' degree.
  -debug                  Displays raw socket messages.
  -verbose                Displays verbose log messages.
  -help                   This help page.

note: 
  The default values can be changed within the config file 
  'socket30003.cfg', section [common] and section [heatmap]. 

Examples:
  heatmap.pl 
  heatmap.pl -data /home/pi -log /var/log 
  heatmap.pl -lat 52.1 -lon 4.1 -maxposition 50000
````
### Output heatmap.pl
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
## Help page rangeview.pl
````
This rangeview.pl script creates location data 
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

Syntax: rangeview.pl

Optional parameters:
  -data <data directory>  The data files are stored in 
                          '/tmp' by default.
  -log  <data directory>  The log files are stored in 
                          '/tmp' by default.
  -output <output         The output file is stored in 
            directory>    '/tmp' by default.
  -file <filename>        The output file name. The extention 
                          (.kml or .csv) determines the 
                          file structure!  
                          'rangeview.kml' by default.
  -filemask <mask>        Specify a filemask. 
                          The default filemask is 'dump*.txt'.
  -override               Override output file if exists. 
                          Default is 'no'.
  -timestamp              Add timestamp to output file name. 
                          Default is 'no'.
  -sequencenumber         Add sequence number to output file name. 
                          Default is 'no'.
  -max <altitude>         Upper limit. Default is '12000 meter'. 
                          Higher values in the input data will be skipped.
  -min <altitude>         Lower limit. Default is '0 meter'. 
                          Lower values in the input data will be skipped.
  -directions <number>    Number of compass direction (pie slices). 
                          Minimal 8, maximal 7200. Default = '1440'.
  -zones <number>         Number of altitude zones. 
                          Minimal 1, maximum 99. 
                          Default = '24'.
  -lon <lonitude>         Location of your antenna.
  -lat <latitude>          
  -distanceunit <unit>,[<unit>] 
                          Type of unit: kilometer, nauticalmile,
                          mile or meter. First unit is for the 
                          incoming source, the file(s) with flight
                          positions. The second unit is for the 
                          output file. No unit means it is the 
                          same as incoming.
                          Default distance unit's are: 
                          'kilometer,kilometer'.
  -altitudeunit <unit>[,<unit>] 
                          Type of unit: feet or meter. First unit
                          is for the incoming source, the file(s) 
                          with flight positions. The second unit 
                          is for the output file. No unit means it 
                          is the same as incoming. 
                          Default altitude unit's are: 
                          'meter,meter'.
  -debug                  Displays raw socket messages.
  -verbose                Displays verbose log messages.
  -help                   This help page.

notes: 
  - The default values can be changed within the config file 'socket30003.cfg'.
  - The source units will be overruled in case the input file header contains unit information.

Examples:
  rangeview.pl 
  rangeview.pl -distanceunit kilometer,nauticalmile -altitudeunit meter,feet
  rangeview.pl -data /home/pi/data -log /home/pi/log -output /home/pi/result 

````
### Output rangeview.pl
* Default output file: /tmp/rangeview.csv
````
type,new_track,name,color,trackpoint,altitudezone,destination,hex_ident,Altitude(meter),latitude,longitude,date,time,angle,distance(kilometer)
T,1,Altitude zone 1: 00000-  500,7fffff00,1,     0,-718,484646,357,52.00493,5.08865,2017/01/10,10:46:15.738,-179.72,8
T,0,Altitude zone 1: 00000-  500,7fffff00,2,     0,-717,484646,357,52.00616,5.08808,2017/01/10,10:46:17.164,-179.32,8
T,0,Altitude zone 1: 00000-  500,7fffff00,3,     0,-714,484646,357,52.00788,5.08722,2017/01/10,10:46:19.740,-178.7,8
T,0,Altitude zone 1: 00000-  500,7fffff00,4,     0,-713,484646,357,52.00914,5.08667,2017/01/10,10:46:21.041,-178.28,8
T,0,Altitude zone 1: 00000-  500,7fffff00,5,     0,-711,484646,357,52.01039,5.08604,2017/01/10,10:46:22.622,-177.79,8
T,0,Altitude zone 1: 00000-  500,7fffff00,6,     0,-709,484646,357,52.01125,5.08560,2017/01/10,10:46:23.892,-177.44,8
T,0,Altitude zone 1: 00000-  500,7fffff00,7,     0,-708,484646,357,52.01230,5.08518,2017/01/10,10:46:25.244,-177.09,8
T,0,Altitude zone 1: 00000-  500,7fffff00,8,     0,-706,484646,357,52.01335,5.08461,2017/01/10,10:46:26.625,-176.62,8
T,0,Altitude zone 1: 00000-  500,7fffff00,9,     0,-704,484646,357,52.01463,5.08400,2017/01/10,10:46:28.031,-176.09,7
T,0,Altitude zone 1: 00000-  500,7fffff00,10,    0,-702,484646,357,52.01579,5.08345,2017/01/10,10:46:29.475,-175.59,7
T,0,Altitude zone 1: 00000-  500,7fffff00,11,    0,-700,484646,357,52.01683,5.08293,2017/01/10,10:46:30.940,-175.11,7
````

* Default output file: /tmp/rangeview.kml
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
      <description>00000-  500</description>
      <styleUrl>#track-1</styleUrl>
      <LineString>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>
5.08865,52.00493,357
5.08808,52.00616,357
5.08722,52.00788,357
5.08667,52.00914,357
5.08604,52.01039,357
5.08560,52.01125,357
5.08518,52.01230,357
5.08461,52.01335,357
5.08400,52.01463,357
5.08345,52.01579,357
5.08293,52.01683,357
etc..
````
## Help page install.pl

````
This install.pl script installs the socket30003 scripts.
It will create the directories, copy the files, check and set the permissions.
In case of an update, it will backup the original config file and add new 
parameters if applicable.

Please read this post for more info:
http://discussions.flightaware.com/post180185.html#p180185

Syntax: install.pl

Optional parameters:
  -install <install       The script will be installed in
            directory>    '/home/pi/socket30003' by default.
  -data <data directory>  The data files will be stored in 
                          '/tmp' by default.
  -log  <data directory>  The log files will be stored in 
                          '/tmp' by default.
  -output <output         The output files will be stored in 
            directory>    '' by default.
  -pid <pid directory>    The pid files will be stored in
                          '/tmp'.
  -debug                  Displays raw socket messages.
  -verbose                Displays verbose log messages.
  -help                   This help page.

Examples:
  install.pl 
  install.pl -install /user/share/socket30003
  install.pl -data /home/pi/data -log /home/pi/log -output /home/pi/result 

````
## Installation
  
### Clone this repo
````
$ cd 
$ mkdir git
$ cd git
$ git clone https://github.com/tedsluis/dump1090.socket30003.git
````
note: be sure 'git' is installed (sudo apt-get install git)  
  
### Edit config file  
  
The best thing is to leave it as much as it is. May change some directories of the unit types (meters, kilometers, miles, feets, nautical miles etc).
````
$ cd dump1090.socket30003
$ vi socket.cfg          (or use an other editor)
````
  
### Run installer
Files wil be copied to the install directory.
````  
$ ./install.pl
````

### Add socket30003.pl as a crontab job
````
$ sudo crontab -e 

*/5 * * * * sudo /home/pi/socket30003/socket30003.pl
````
note: script will start every 5 minutes if it is not running anymore.

### Check the log and output file
````
$ cat /tmp/*dump1090*.log | less
$ cat /tmp/*dump1090*.txt | less
````

### Run heatmap.pl
   
Wait a couple of days to be sure you have enough data.  
````
$ cd
$ cd socket30003
$ ./heatmap 
````
You can find the result in '/tmp/heatmap.csv'.

### Run rangview.pl

````
$ cd
$ cd socket30003
$ ./rangview.pl
````
You can find the result in 'rangview.kml'.

### View the heatmap
  
Be sure you have my version of dump1090 mutability installed: https://github.com/tedsluis/dump1090

Copy the heatmap.csv to /usr/share/dump1090-mutability/html/
````
$ sudo cp /tmp/heatmap.csv /usr/share/dump1090-mutability/html/heatmapdata.csv
```` 
Optional: change the name and the path of the heatmap within '/usr/share/dump1090-mutability/html/config.js'.  
  
Refresh the dump1090 web GUI and toggle the [heatmap] button.
  
### View the rangeview  
  
Be sure you have my version of dump1090 mutability installed: https://github.com/tedsluis/dump1090
  
Copy the rangview.kml to a webserver where it can be publicly accessed (nessesary for the Google maps API).  

Edit and fill in the URL of the rangeview.kml after 'UserMap='.
````
$ sudo vi /usr/share/dump1090-mutability/html/config.js 
````
  
Refresh the dump1090 web GUI and toggle the [heatmap] button.

## More info

* https://github.com/tedsluis/dump1090
* https://www.youtube.com/watch?v=Qz4XSFRjLTI
* http://discussions.flightaware.com/ads-b-flight-tracking-f21/heatmap-range-altitude-view-for-dump1090-mutability-v1-15-t35844.html
* ted.sluis@gmail.com
