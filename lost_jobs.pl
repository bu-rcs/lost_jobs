#!/usr/bin/perl
# (c) Boston University
# Author: Katia Bulekova
# May, 2025
#
use strict;
use warnings;
use Time::Piece;

# Check if the input file and threshold value are provided
if (@ARGV < 1) {
    die "Usage: $0  [-v] <YYYY-MM-DD>\n    where is the date of the event.";
}

# Input file and threshold value
my $verbose = 0;   # Flag to enable verbose output
my $file ="/usr/local/sge/common/accounting" ;

if ($ARGV[0] eq '-v') {
    $verbose = 1;
    shift @ARGV;                # Remove the -v flag from @ARGV
}

# Get the date of the event
my $date = $ARGV[0];

# Convert Date to the epoch time and subtract one calendar day:
my $t = Time::Piece->strptime($date, '%Y-%m-%d');
my $threshold_value = $t->epoch - 24*60*60;
print "The epoch time for $date is $threshold_value\n";

# Open the file for reading
open my $fh, '<', $file or die "Could not open file '$file': $!\n";

# Variables to track processing
my $found_first_job = 0;   # Flag to indicate the first matching job has been found
my %user_counts = ();      # Hash to store counts for unique values in the 4th column
my $total_records = 0;

while (my $line = <$fh>) {
    # Skip comments and empty lines
    next if $line =~ /^\s*#/;

    # Split the line into fields
    my @fields = split /:/, $line;

    # Make sure the line has enough fields to process
    next unless @fields >= 11;

    # If the first job with 9th column >= threshold hasn't been found yet
    if (!$found_first_job && $fields[8] >= $threshold_value) {
        $found_first_job = 1;
    }

    # Once the first job is found, process subsequent records
    if ($found_first_job) {

	
        # Check if 10th and 11th fields contain zeros or "-"
        if (($fields[8] ne "0" ) && ($fields[9] eq "0" || $fields[9] eq "-") && ($fields[10] eq "0" || $fields[10] eq "-")) {
 
	    print "$line" if $verbose;
            # Update counts for the 4th column (unique user identification)
            my $user = $fields[3];
            $user_counts{$user}++;
	    $total_records++;
        }
    }
}

# Close the input file
close $fh;

# Calculate total number of unique users
my $unique_users = scalar keys %user_counts;

# Print results
print "\n--- Summary ---\n";
print "Number of unique users: $unique_users\n";
print "Total number of lost jobs: $total_records\n";

# Print results
print "\nUnique values in the 4th column and their counts:\n";
foreach my $user (sort keys %user_counts) {
    print "$user: $user_counts{$user}\n";
}
