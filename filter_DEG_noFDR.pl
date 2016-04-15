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

my ($cut,$in,$out,$com);
GetOptions(
			"h|?"		=>	\&help,
			"in:s"		=>	\$in,
			"out:s"	=>	\$out,
			"cut:s"	=>	\$cut,
			"com:s"	=>	\$com,
			) || &help;
&help unless ($in  && $out );

sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: ......
    Usage:
        -in            <file>                         force
        -cut           <num>  default 2
        -out           <file>                         force
        -com          T1,T2;T3,T4                     option
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
my @ID1;my @ID2;my @filter;my $HEAD;
$cut ||=2;
open(IN,$in)|| die $!;
while (<IN>) {
	chomp;
	my @temp=split/\t+/,$_;
	if (/\#/) {
		$HEAD=$_;
		my @ID;my $id_number=0;
		for (my $i=0;$i<@temp;$i++) {
			unless ($temp[$i]=~/ID|FDR|log2FC|regulated/) {
				$ID[$id_number]=$i;
				$id_number++;
			}
		}
		for (my $i=0;$i<(@ID/2);$i++) {
			push @ID1,$ID[$i];
		}
		for (my $i=(@ID/2);$i<@ID;$i++) {
			push @ID2,$ID[$i];
		}
		next;
	}
	my @FC1;my @FC2;

	foreach my $row (@ID1) {
		push @FC1,$temp[$row];
	}
	foreach my $row (@ID2) {
		push @FC2,$temp[$row];
	}

	my $compare=&compare(\@FC1,\@FC2,$cut);
	if ($compare ==1 ) {
		push @filter,$_;
	}
}

close IN;

if (@filter>0) {
	open (OUT,">$out") || die $!;
		print OUT "$HEAD\n";
		print OUT join"\n",@filter;
	close OUT;
}


sub compare(){
	my ($group1,$group2,$cut)=@_;
	$cut ||=2;
	my $max1=&max($group1);
	my $min1=&min($group1);
	my $max2=&max($group2);
	my $min2=&min($group2);
	if ($min1>($max2*$cut)   || ($max1*$cut)<$min2) {
	
		return ("1");
	}else{
		return ("0");
	}
}


sub max(){
	my ($data)=@_;
	my ($max)=sort {$b <=> $a} @$data;
	return($max);
}

sub min(){
	my ($data)=@_;
	my ($min)=sort {$a <=> $b} @$data;
	return ($min);
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

