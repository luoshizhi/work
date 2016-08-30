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

if (@ARGV < 2) {
	print "Usage:\tperl $0 lncRNA_target DEG_mRNA\n";
	exit
}
my %lncRNA_target;my %target;
open (TARGET,"$ARGV[0]") or die $!;
while (<TARGET>){
	chomp;
	next if (/^#/);
	my ($lnc,@mRNA)=split/\s+|;/,$_;
	foreach my $mRNA_id (@mRNA) {
		$lncRNA_target{$lnc}{$mRNA_id}=undef;
		$target{$mRNA_id}=undef;
	}
}
close TARGET;
my %DEG_target;
open (DEG,"$ARGV[1]") or die $!;
while (<DEG>){
	chomp;
	next if (/^#/);
	my ($mRNA_id,$updown)=(split/\t+/,$_)[0,-1];
	if (exists $target{$mRNA_id}) {
		$DEG_target{$mRNA_id}=$updown;
	}
}
close DEG;

my %DEG_lncRNA_target;
foreach my $lnc(sort keys %lncRNA_target){
	foreach my $mRNA(sort keys %{$lncRNA_target{$lnc}}){
		if (exists $DEG_target{$mRNA}) {
			$DEG_lncRNA_target{$lnc}{$mRNA}=undef;
		}
	}
}


foreach my $lnc (sort keys %DEG_lncRNA_target) {
	my $target=join";",(sort keys %{$DEG_lncRNA_target{$lnc}});
	print "$lnc\t$target\n";
}



