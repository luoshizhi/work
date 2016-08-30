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

my ($od,$mature,$trans,$score);
GetOptions(
			"h|?"		=>	\&help,
			"od:s"	=>	\$od,
			"m:s"	=>	\$mature,
			"t:s"	=>	\$trans,
			"r:s"	=>	\$score,
			) || &help;
&help unless ( $od && $mature && $trans);

sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: ......
    Usage:
        -od    <file>   force
        -t     [str]    FASTA formatted transcripts or cDNA sequence
        -m     [str]    FASTA formatted mature small RNA sequences file
        -r     [int]    Target finder Cutoff Score. Range(1-7) (default: 7)
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
$score ||=4;
open MI,"<$mature" or die $!;
my %miR;
my $id;
while (<MI>) {
	chomp;
	if (/^>(\S+)/) {
		$id = $1;
	} else {
		$miR{$id} .= $_;
	}
} 
close MI;$trans=&ABSOLUTE_DIR($trans);
####################Target Finder###########################################################################
print  "Target Finder Start......\n\n";
mkdir $od if !-d $od;
$od=&ABSOLUTE_DIR($od);
unless(-d "$od/Out_TargetFinder_score$score"){
mkdir "$od/Out_TargetFinder_score$score",0755 or die $!;} 
 unless(-d "$od/work_sh"){mkdir "$od/work_sh"or die $!;}
open TF,">$od/work_sh/targetfind_$score.sh"or die $!;
my $target_out;
for my$ID (keys %miR) {
	$target_out = $ID . "_targetout";
	print TF "perl $Bin/targetfinder.pl -s $miR{$ID} -d $trans -q $ID -c $score > $od/Out_TargetFinder_score$score/$target_out 2> $od/log_targetfinder &&\n";
	print  "perl $Bin/targetfinder.pl -s $miR{$ID} -d $trans -q $ID -c $score > $od/Out_TargetFinder_score$score/$target_out 2> $od/log_targetfinder &&\n";
} 
close TF;
`ssh cluster qsub-sge.pl --queue all.q  $od/work_sh/targetfind_$score.sh --reqsub --maxproc 80 --independent`;
undef %miR;
print  "Target Finder Done......\n\n";
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
		warn "Warning just for file and dir:$in\n";
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

