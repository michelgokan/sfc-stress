#!/bin/perl

#my $csv_file = "../ergeg/erg/ergergreg/aaa.log";
my $csv_file = "/aaa.log";
($file = $csv_file) =~s/.*\///;
(my $sheet_name = $file) =~ s/\.[^.]+$//;   # strip extension
$sheet_name =~ s/[\$#@~!&*()\[\];.,:?^ `\\\/]+//g;
print "$sheet_name\n"
