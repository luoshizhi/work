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

if (@ARGV<1) {
	print "1.get the longest cds to gene\n";
	print "2.filter the seq less than 20\n";
	print "$0  cds.fa  > out\n";
	exit;
}

my %hash;
$/=">";
open (IN,"$ARGV[0]") or die $!;
while (<IN>){
	chomp;
	s/\r//g;
	my($id,$seq)=split/\n/,$_,2;
	next unless ($id && $seq);
	next if (length($seq)<=30);
	#$seq=~s/\n//g;
	($id)=$id=~/([0-9A-Za-z_.]+)/;
	if (exists $hash{$id}){
		if (length($seq) > length($hash{$id})){
			$hash{$id}=$seq;
		}
	}else{
		$hash{$id}=$seq;
	}
}
close IN;
foreach(sort keys %hash){
	print ">$_\n$hash{$_}"
}
