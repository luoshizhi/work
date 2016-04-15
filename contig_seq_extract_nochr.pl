#!/usr/bin/perl -w
# Copyright (c) BMK 2012/8/30
# Writer:         Luosz <luosz@biobreeding.com.cn>
# Program Date:   2015/12/10


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
my ($gff,$fa,$out);
GetOptions(
			"h|?" =>\&help,
			"o:s"=>\$out,
			"gff:s"=>\$gff,
			"fa:s"=>\$fa,
			) || &help;
&help unless ($gff && $fa && $out);

sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: extract contig seq from contig.fa but no contig asembly in chr(提取congtig序列，去除已组装到染色体的contig）
    Usage:
        -gff          contig.gff       forced

        -fa         config.fa        forced

        -o          config_nochr.fa  forced

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
my %contig;
while (<GFF>) 
{
	chomp;
	my ($chr,$detail)=(split/\t/,$_)[0,-1];
	if ($chr=~/unanchored/) {
		$detail=/ID=(.+?);/;
		$contig{$1}=1;
	}
}

close (GFF) ;

open (FA,"$fa") or die $!;
$/=">";
<FA>;
while (<FA>) {
	chomp;
	my($id,$seq)=split/\n/,$_,2;
	if (exists $contig{$id}) {
		print OUT ">$_";
	}
}
close (OUT) ;

###############Time
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
print "\nEnd $programe_dir Time :[$Time_End]\n\n";
&Runtime($BEGIN);


###############Subs
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

