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

if (@ARGV<2) {
	print "$0  id_list fa -1 > out\n";
	print "-1 : one line seq\n";
	print "-2 : more line seq\n";
	exit;
}

$ARGV[2] ||=1;
open (IN,"$ARGV[0]") or die $!;
my %id;
while (<IN>){
	chomp;
	s/\r//g;
	$id{lc($_)}=$_;
}
close IN;

$/=">";
open (IN,"$ARGV[1]") or die $!;
while (<IN>){
	chomp;
	s/\r//g;
	my($id,$seq)=split/\n/,$_,2;
	next unless ($id && $seq);
	$seq=~s/\n$//;
	($id)=$id=~/(\S+)/;
#	print "$id\n";
	$seq=~s/\n//g if ($ARGV[2] ==1 );
	if (exists $id{lc($id)}) {
		print ">$id{lc($id)}\n$seq\n";
	}
}
close IN;