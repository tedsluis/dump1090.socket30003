#!/usr/bin/perl -w
# Ted Sluis 2015-12-20
# Filename : common.pm
#===============================================================================
# common sub routines 
#===============================================================================
package common;
use strict;
use warnings;
use POSIX qw(strftime);
use Time::Local;
use Getopt::Long;
use File::Basename;
use Term::ANSIColor qw(:constants);
#===============================================================================
my %config;
my $myDebug;
my $interactive = 0;
my $account;
my $verbose;
my $logfile;
my @errorlog;
my @tmplog;
#===============================================================================
sub InteractiveShellCheck(@) {
        #
        # Do we run this script interactive or not?
        # If so, turn on verbose logging.
        #
        # Input: none. You can force interactive or non interactive mode using 0 or 1.
        # Return: 1=interactive, 0=not interactive.
        #
        if ( defined ($_[0]) && $_[0] eq "common" ) { shift; }
        if ( defined ($_[0]) ){
		# Force interactive or non interactive mode using 0 or 1.
                if ($_[0]){
                        $interactive = 0;
                        LOG($logfile,"Forcing Interactive to OFF","D");
                        return 0;
                } else {
                        $interactive = 1;
                        LOG($logfile,"Forcing Interactive to ON","D");
                        return 1;
                }
        }
        if ($myDebug){
                if (-t STDIN){
                        LOG($logfile,"Interactivity test -> STDIN = 1","D");
                } else {
                        LOG($logfile,"Interactivity test -> STDIN = 0","D");
                }
                if (-t STDOUT){
                        LOG($logfile,"Interactivity test -> STDOUT = 1","D");
                } else {
                        LOG($logfile,"Interactivity test -> STDOUT = 0","D");
                }
        }
        if (-t STDIN && -t STDOUT){
                # Running interactive
                $interactive = 1;
                return 1;
        }
        return 0;
}
#===============================================================================
sub Account(@){
        #
	# Determine the account that is being used.
        #
        # Input: none
        # Return: hash with key;
        #               user
        #
        if ( defined ($_[0]) && $_[0] eq "common" ) { shift; }
        $account = `id -u --name`;
        chop($account);
	LOG($logfile,"Account=$account","D");
        return $account;
}
$account = Account();
#===============================================================================
# Read configfile
sub READCONFIG(@) {
	#
	# This routine will read the config file.
	# It looks for the sections and ignor those which do not apply.
	# It checks the INI file format and removes comments.
	#
	if ( defined($_[0]) && $_[0] eq "common" ) { shift; }
	# config file name:
	my $config = shift;
	# full scriptname:		
	my $fullscriptname = shift;
        my $scriptname  = basename($fullscriptname);
        my $directoryname = dirname($fullscriptname);
	# path to config file
	$config = $directoryname.'/'.$config;
	LOG($logfile,"Reading parameters and values from '$config' config file:","I");
	if (!-e $config) {
		LOG($logfile,"Can not read config! Config file '$config' does not exists!","W");
		return 0;
	} elsif (!-r $config) {
		LOG($logfile,"Can not read config! Config file '$config' is not readable!","W");
		return 0;
	} else {
		my @cmd = `cat $config`;
		my $section;
		foreach my $line (@cmd) {
			chomp($line);
			# skip lines with comments:
			next if ($line =~ /^\s*#/);
			# skip blank lines:
			next if ($line =~ /^\s*$/);
			# Get section:
			if ($line =~ /^\s*\[([^\]]+)\]\s*(#.*)?$/) {
				$section = $1;
				LOG($logfile,"Section: [$section]","I") if (($section =~ /common/) || ($scriptname =~ /$section/));
				next;
			} elsif ($line =~ /^([^=]+)=([^\#]*)(#.*)?$/) {
				# Get paramter & value
				my $parameter = $1;
				my $value = $2;
				# remove any white spaces at the begin and the end:
				$parameter =~ s/^\s*|\s*$//g;
				$value     =~ s/^\s*|\s*$//g;
				if ((!$parameter) || ($parameter =~ /^\s*$/)) {
					LOG($logfile,"The line '$line' in config file '$config' is invalid! No parameter specified!","W");
					next;
				}
				if ((!$section) || ($section =~ /^\s*$/)) {
					LOG($logfile,"The line '$line' in config file '$config' is invalid! No section specified jet!","W");
					next;
				}
				# save section, parameter & value
				next unless (($section =~ /common/) || ($scriptname =~ /$section/));
				$config{$section}{$parameter} = $value;
				LOG($logfile,"   $parameter = $value","I");
			} else {
				# Invalid line:
				LOG($logfile,"The line '$line' in config file '$config' is invalid!","W");
				LOG($logfile,"Valid lines looks like:","I");
				LOG($logfile,"# comment line","I");
				LOG($logfile,"[some_section_name]","I");
				LOG($logfile,"parameter=value","I");
				LOG($logfile,"Comment text (started with #) behind a section or parameter=value is allowed!","I");
				next;
			}
		}
	}
	return %config;
}
#===============================================================================
sub LOGset(@){
        #
        # LOGset routine sets the log path. If the log file does
	# not exists, it will be created and the permissions will
	# be set. 
        #
        # Input: path to log file.
        # Input: log file name.
        # Return: full path and log file name.
        #
        if ( defined($_[0]) && $_[0] eq "common" ) { shift; }
        my $logpath = shift;
        my $name = shift;
	if (!-d $logpath) {
                LOG("The log file directory '$logpath' does not exists!","E");
                exit 1;
        }
	if (!-x $logpath) {
		LOG("The log file directory '$logpath' is not writeable!","E");
		exit 1;
	}
        $logfile =  "$logpath/$name";
        system("touch $logfile") unless (-f $logfile);
        chmod(0666,$logfile);
        LOG($logfile,"=== NEW RUN MARKER ============================","H");
        return $logfile;
}
#===============================================================================
sub setdebug(@){
        #
        # Sets debug mode and triggers verbose logging
        #
        # Input: none
        # Return: none
        #
        if ( $_[0] eq "common" ) { shift; }
        $myDebug += 1;
        LOG($logfile,"Setting debug ON!","I");
        LOGverbose();
}
#===============================================================================
sub LOGverbose(@){
        #
        # Sets verbose logging mode. 
        #
        # Input: none or 'off' to disable verbose logging.
        # Return: none
        #
        if ( defined($_[0]) && $_[0] eq "common" ) { shift; }
        my $level = shift || 0;
        if ($level eq "off"){
                $verbose = 0;
                LOG($logfile,"Setting verbose OFF due to off switch.","D");
                return;
        }
        $verbose = 1;
        LOG($logfile,"Setting verbose ON.","D");
}
#===============================================================================
sub LOG(@) {
	#
	# Write messages to log file and display.
	# Adds alert color to Debug messages, Errors and Warnings.
	#
        # first field must be log file.
        # second field must be message.
        # third field informational or error.
        #
        if ( defined($_[0]) && $_[0] eq "common" ) { shift; }
        my $LOG  = shift || "";
        my $text = shift || "";
        my $type = shift || "I";
	#
	# D = Debug message.
	# E = Error message.
	# H = Log file only, reservered for === NEW RUN MARKER ===.
	# I = Informational log message.
	# L = Log file only, but can be displayed using verbose.
	# W = Warning message.
	#
	# Test type
        if ( $type eq "D" ){
                # Displays debug info whenever debug is on.
                return unless $myDebug;
                $text = sprintf("pid=%-5s ",$$).(sprintf MAGENTA). "$type **DEBUG** $account $text" .sprintf RESET;
        } elsif ( $type =~ /H/ ) {
		# Writes only to log file:
                $text = sprintf("pid=%-5s ",$$)."- $account $text";
        } elsif ( $type =~ /I/ ) {
		# Informational log message for log file & display.
                $text = sprintf("pid=%-5s ",$$)."$type $account $text";
	} elsif ( $type =~ /L/ ) {
                # Informational log message for log file only.
                $text = sprintf("pid=%-5s ",$$)."$type $account $text";
        } elsif ( $type =~ /E/ ) {
		# Error message
                $text = sprintf("pid=%-5s ",$$).(sprintf RED). "$type $account $text" .sprintf RESET;
        } elsif ( $type =~ /W/ ) {
		# Warning message
                $text = sprintf("pid=%-5s ",$$).(sprintf YELLOW). "$type $account $text" .sprintf RESET;
        } else {
                # Every other type of message
                $text = sprintf("pid=%-5s ",$$)."I $account $text (onbekend logtype=$type)";
        }
        $text = strftime("%d%b%y %H:%M:%S", localtime())." $text";
	# Added to message queue
	if (($type =~ /H/) && ($text) && ($text =~ /NEW\sRUN\sMARKER/)) {
		# Add on start
		unshift(@tmplog,$text);
	} else {
		# Add on end
		push(@tmplog,$text);
	}
	# Do we have a log file jet?
	if (($LOG) && ($LOG !~ /^\s*$/) && (-w $LOG)) {
        	# Write all messages in queue to log file.
        	open (OUT,">>$LOG") or die "Cannot open logfile '$LOG' for output; Reason $! ! \n";
		foreach my $line (@tmplog) {
			# remove ansi codes before writing to log file.
			$line =~ s/\x1b\[[0-9;]*m//g;
        		print OUT $line."\n";
		}
		# empty message queue
		@tmplog=();
        	close OUT;
	}
	# 
        return if $type eq "H";
        # Write message to display
        if (($interactive) && ((($type =~ /L/) && ($verbose)) || ($type =~ /[EIDW]/))) {
        	print $text."\n";
        }
	# Store Errors & Warnings
        if ( $type =~ /[EW]{1}/ ){
		# remove ansi codes before writing to log file.
		$text =~ s/\x1b\[[0-9;]*m//g;
                push(@errorlog,"$type;$text");
        }
} # Einde LOG

1;
