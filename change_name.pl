#!/usr/bin/perl
use strict;
use warnings;

print "Hello, World...\n";
open (IN,$ARGV[0]) or die $!;
my %hash;
while (<IN>) {
	chomp;
	my($key,$value)=split;
	$hash{$key}=$value;
}
close IN;

my $file=`find ./ -name "*_vs_*"`;
my @file=split/\n/,$file;
foreach  (@file) {
	my $old=$_;
	my @a=$_=~/(\w+?_vs_\w+)/g;
	#print "@a\n";
	foreach my $a (@a) {
		if (exists $hash{$a}) {
			s/$a/$hash{$a}/;
			print "mv $old $_\n"; 
		}
	}
}
