#!/usr/bin/perl -w
# Copyright (c) BMK 2012/8/30
# Writer:         Luosz <luosz@biobreeding.com.cn>
# Program Date:   2014/7/29


use strict;
use Cwd;
use Getopt::Long;
use Data::Dumper;
use File::Basename qw(basename dirname);
use FindBin qw($Bin $Script);

my $programe_dir=basename($0);
my $path=dirname($0);

my $ver    = "1.0";
my $Writer = "Luosz <luosz\@biomarker.com.cn>";
my $Data   = "2014/7/29";
my $BEGIN=time();
#######################################################################################

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($gff,$out);
GetOptions(
			"h|?" =>\&help,
			"o:s"=>\$out,
			"gff:s"=>\$gff,
			) || &help;
&help unless ($gff && $out);

sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: tran contig gff to normal gff for ref_tran_v1.5 process 
    Usage:
        -gff        infile     must be given

        -o          outfile    must be given

        -h          Help document
	Usage End.
	exit;
}
# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------

###############Time
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart $programe_dir Time :[$Time_Start]\n\n";
################

open (GFF,"$gff") || die $!;

open (OUT,">$out") || die $!;

while (<GFF>) 
{
	chomp;
	my ($chr,$source,$type,$start,$end,$sorce,$strand,$phase,$attributes)=split/\t/,$_;
	my $contig=undef;
	if($chr=~/unanchored/){
		if ($type=~/mRNA/) {
			($contig)=$attributes=~/CONTIG=([a-zA-Z0-9._]+)/;
			$attributes=~s/(ID=.+?);/${1}_mRNA;/;
			$attributes=~s/Name=(.+?);/Name=${1}_mRNA;Parent=$1;/;
			my $gene="$contig\t$source\tgene\t$start\t$end\t$sorce\t$strand\t$phase\tID=$1;Name=$1";
			my $mRNA="$contig\t$source\t$type\t$start\t$end\t$sorce\t$strand\t$phase\t$attributes";
			print OUT "$gene\n$mRNA\n";
		}
		if ($type=~/CDS/) {
			($contig)=$attributes=~/CONTIG=([a-zA-Z0-9._]+)/;
			$attributes=~s/(Parent=.+?);/${1}_mRNA;/;
			my $CDS="$contig\t$source\t$type\t$start\t$end\t$sorce\t$strand\t$phase\t$attributes";
			print OUT "$CDS\n";
		}
	}else{
		if ($type=~/mRNA/) {
			($contig)=$attributes=~/CONTIG=([a-zA-Z0-9._]+)/;
			$attributes=~s/(ID=.+?);/${1}_mRNA;/;
			$attributes=~s/Name=(.+?);/Name=${1}_mRNA;Parent=$1;/;
			my $gene="$chr\t$source\tgene\t$start\t$end\t$sorce\t$strand\t$phase\tID=$1;Name=$1";
			my $mRNA="$chr\t$source\t$type\t$start\t$end\t$sorce\t$strand\t$phase\t$attributes";
			print OUT "$gene\n$mRNA\n";
		}
		if ($type=~/CDS/) {
			($contig)=$attributes=~/CONTIG=([a-zA-Z0-9._]+)/;
			$attributes=~s/(Parent=.+?);/${1}_mRNA;/;
			my $CDS="$chr\t$source\t$type\t$start\t$end\t$sorce\t$strand\t$phase\t$attributes";
			print OUT "$CDS\n";
		}
	}
}
close (GFF) ;
close (OUT) ;

###############Time
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
print "\nEnd $programe_dir Time :[$Time_End]\n\n";
&Runtime($BEGIN);


###############Subsq
sub sub_format_datetime #Time calculation subroutine
{
	my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
	$wday = $yday = $isdst = 0;
	sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

sub Runtime # &Runtime($BEGIN);
{
	my ($t1)=@_;
	my $t=time()-$t1;
	print "Total $programe_dir elapsed time : [",&sub_time($t),"]\n";
}
sub sub_time
{
	my ($T)=@_;chomp $T;
	my $s=0;my $m=0;my $h=0;
	if ($T>=3600) {
		my $h=int ($T/3600);
		my $a=$T%3600;
		if ($a>=60) {
			my $m=int($a/60);
			$s=$a%60;
			$T=$h."h\-".$m."m\-".$s."s";
		}else{
			$T=$h."h-"."0m\-".$a."s";
		}
	}else{
		if ($T>=60) {
			my $m=int($T/60);
			$s=$T%60;
			$T=$m."m\-".$s."s";
		}else{
			$T=$T."s";
		}
	}
	return ($T);
}

sub ABSOLUTE_DIR #$pavfile=&ABSOLUTE_DIR($pavfile);
{
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
		$return="$dir/$file";
	}elsif(-d $in){
		chdir $in;$return=`pwd`;chomp $return;
	}else{
		warn "Warning just for file and dir\n";
		exit;
	}
	chdir $cur_dir;
	return $return;
}

