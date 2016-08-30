#!/usr/bin/perl -w
# Copyright (c) BRD 2015/12/29
# Writer:         Luosz <luosz@biobreeding.com.cn>
# Program Date:   2015/12/29.


use strict;
use Cwd;
use Getopt::Long;
use Data::Dumper;
use File::Basename qw(basename dirname);
use FindBin qw($Bin $Script);

if (@ARGV != 2) {
	print "\nUsage:\t\nperl $0  mutmap_pileup_file  outfile\n\n";
	exit;
}

my %code1=(
"A"=>"A","T"=>"T","C"=>"C","G"=>"G",
"R"=>"AG","Y"=>"CT","M"=>"AC","K"=>"GT","S"=>"CG","W"=>"AT",
"H"=>"ACT","B"=>"CGT","V"=>"ACG","D"=>"AGT","N"=>"ATCG","-"=>"ATCG","?"=>"ATCG",
);

my %code2=(
"T"=>"T","C"=>"C","A"=>"A","G"=>"G",
"TT"=>"T","CC"=>"C","AA"=>"A","GG"=>"G",
"CG"=>"S","AG"=>"R","AC"=>"M","GT"=>"K","CT"=>"Y","AT"=>"W",
"GC"=>"S","GA"=>"R","CA"=>"M","TG"=>"K","TC"=>"Y","TA"=>"W",
"ATCG"=>"N","ACG"=>"V","ACT"=>"H","AGT"=>"D","CGT"=>"B","ATCG"=>"?","ATCG"=>"-",
);

open (OUT,">$ARGV[1]") or die $!;
print OUT "\#Chr\tPos\tRef\tR02_base\tR02_depth\tR02_snp_index\tR01_base\tR01_depth\tR01_snp_index\tdelta_snp_index\tp_value\n";
open (IN,"$ARGV[0]") or die $!;
while (<IN>){
	chomp;
	my($chr,$pos,$ref,$mt_alt,$mt_depth,$mt_snp_index,$WT_alt,$WT_depth,$WT_snp_index,$delta,$p)=(split/\t+/,$_)[0,1,2,3,7,10,14,18,21,22,27];
#	next if ($mt_depth<=3 || $WT_depth <=3);
	my($mt_bases,$WT_bases)=(split/\t+/,$_)[8,19];
	$mt_alt=&type_snp($mt_bases,$ref,$mt_depth,$chr,$pos);
	$WT_alt=&type_snp($WT_bases,$ref,$WT_depth,$chr,$pos);
	my @out=($chr,$pos,$ref,$mt_alt,$mt_depth,$mt_snp_index,$WT_alt,$WT_depth,$WT_snp_index,$delta,$p);
	print OUT join"\t",@out;
	print OUT "\n";

}
close IN;
close OUT;
sub type_snp()  #
{
	my ($bases,$ref,$depth,$chr,$pos)=@_;
	$bases=uc($bases);
	my @alt=$bases=~/([A|T|C|G])/g;
	my %alt;
	$alt{$_} ++ foreach @alt;
	my ($alt)=$bases=~/([A|T|C|G])/;
	
	if ((keys %alt) > 1) {
		my $max_alt;my $max;
		foreach (keys %alt){
			if (!defined $max_alt) {
				$max_alt=$_;
				$max=$alt{$_};
				next;
			}
			if ($max < $alt{$_}){
				$max=$alt{$_};
				$max_alt=$_;
			}
		}
	}
	if ($bases=~/\.|\,|\*/){
		$alt .=$ref;
	}
	my $type = $code2{$alt};
	return $type;
}
