#!/usr/bin/env perl
## Credits: @glenn jackman
## Modifications: Michel Gokan Khan 
## url: https://askubuntu.com/questions/1080394/how-to-combine-multiple-csv-files-to-one-ods-file-on-the-command-line-one-sheet

use strict;
use warnings;
use autodie;
# CPAN modules required:
use Spreadsheet::Write;
use Text::CSV;

my $xlsx_file = shift @ARGV;
$xlsx_file .= ".xlsx" unless $xlsx_file =~ /\.xlsx$/;
my $xlsx = Spreadsheet::Write->new(file => $xlsx_file);
my $csv = Text::CSV->new({binary => 1});

for my $csv_file (@ARGV) {
    my @rows = ();
    open my $fh, "<:encoding(utf8)", $csv_file;
    while (my $row = $csv->getline($fh)) {
        push @rows, $row;
    }
    $csv->eof or $csv->error_diag();
    close $fh;  
    
    $csv_file =~ s/.*\///;
    (my $sheet_name = $csv_file) =~ s/\.[^.]+$//;   # strip extension
    $sheet_name =~ s/[\$#@~!&*()\[\];.,:?^ `\\\/]+//g;
    $xlsx->addsheet($sheet_name);
    $xlsx->addrows(@rows);
}
$xlsx->close();
