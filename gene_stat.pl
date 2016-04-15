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

my $programe_dir=basename($0);
my $path=dirname($0);

my $ver    = "1.0";
my $Writer = "Luosz <luosz\@biobreeding.com.cn>";
my $Data   = "2015/12/29";
my $BEGIN=time();
#######################################################################################

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------

my ($out,$map,$gene,$sam,$depth,$key);
GetOptions(
			"h|?"		=>	\&help,
			"map:s"		=>\$map,
			"out:s"	=>	\$out,
			"gene:s"	=>\$gene,
			"sam:s"	=>\$sam,
			"depth:s"=>\$depth,
			"key:s"=>\$key
			) || &help;
&help unless ( $out && $map && $gene && $sam && $depth);

sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: ......
    Usage:
        -map         mapstat
        -out           <file>                         force
        -gene 
        -sam
        -depth
        -key  
        -h          Help document

	Usage End.
	exit;
}
# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------


###############Time
my $Time_Start;my $time_p=time();
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart $programe_dir Time :[$Time_Start]\n\n";
################

my %total_reads;
open (MAP,$map) || die $!;
while (<MAP>) {
	chomp;
	my($ID,$read)=split;
	$total_reads{$ID}=$read;
}

my %gene;
open (GENE,$gene) || die $!;
$/=">";
<GENE>;
while (<GENE>) {
	chomp;
	my ($id,$seq)=split/\n/,$_,2;
	$id=~s/\n//;
	$seq=~s/\n//;
	$gene{$id}=length($seq);
}

$/="\n";
my %gene_read;
my %uniq_read;
my %muli_read;
open(SAM,$sam) || die $!;
while (<SAM>) {
	chomp;
	my ($gene_id,$sorce)=(split/\s+/,$_)[2,4];
	next unless exists $gene{$gene_id};
	$gene_read{$gene_id}++;
	if ($sorce==50){
		$uniq_read{$gene_id} ++;
	}else{
		$muli_read{$gene_id} ++;
	}
}
my %exon;
my %base;
open (DEPTH,$depth)|| die $!;
while (<DEPTH>) {
	chomp;
	my ($id,$base)=(split/\s+/,$_)[0,2];
	$exon{$id} ++;
	$base{$id} +=$base;
}
open (OUT,">$out") ||die $!;
print OUT join"\t","#Sample","gene_id","Length","Depth","Coverage","RPKM","TotalReads","UniqReads","MulitPosiReads","\n";
foreach my $gene_id (sort keys %gene) {
	my $Length=$gene{$gene_id};
	my $Depth=$base{$gene_id}/$Length;
	my $Coverage=$exon{$gene_id}/$Length;
	my $RPKM=$gene_read{$gene_id}/(($total_reads{$key}/1000000)*($Length/1000));
	my $TotalReads=$gene_read{$gene_id};
	my $UniqReads=$uniq_read{$gene_id};
	my $MulitPosiReads=$muli_read{$gene_id};
	$UniqReads ||=0;
	$MulitPosiReads ||=0;
	$TotalReads ||=0;
	print OUT join"\t",$key,$gene_id,$Length,$Depth,$Coverage,$RPKM,$TotalReads,$UniqReads,$MulitPosiReads;
	print OUT "\n";
}


###############Time
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
print "\nEnd $programe_dir Time :[$Time_End]\n\n";
&Runtime($BEGIN);


############################################################################
############################################################################



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

#sub show_log()
#{
#	my ($txt) = @_ ;
#	my $time = time();
#	my $Time = &sub_format_datetime(localtime($time));
#	print "$Time:\t$txt\n" ;
#	print LOG "$Time:\t$txt\n";
#	return ($time) ;
#}

#&run_or_die($cmd);
sub run_or_die()
{
	my ($cmd) = @_ ;
	&show_log($cmd);
	my $flag = system($cmd) ;
	if ($flag != 0){
		&show_log("Error: command fail: $cmd");
		exit(1);
	}
	&show_log("done.");
	return ;
}

sub run_or_die_cmds{ 
	my ($cmd) = @_;
	my @cmd=split/\n/,$cmd;
	foreach my $work(@cmd) {
		&run_or_die($work);
	}
	return;
}
sub qsub()
{
	my ($shfile, $queue, $ass_maxproc) = @_ ;
	$queue ||= 'general.q' ;
	$ass_maxproc ||= 30 ;
	if (`hostname` =~ /cluster/){
		my $cmd = "perl qsub-sge.pl --maxproc $ass_maxproc --queue $queue --resource vf=15G --reqsub $shfile --independent" ;
		&run_or_die($cmd);
	}
	else{
		my $cmd = "ssh cluster -Y perl qsub-sge.pl --maxproc $ass_maxproc --queue $queue --resource vf=15G --reqsub $shfile --independent" ;
		&run_or_die($cmd);
	}

	return ;
}

