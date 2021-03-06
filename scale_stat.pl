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

my ($i,$out,$cut,$scale,$range);
GetOptions(
			"h|?"		=>	\&help,
			"i:s"		=>	\$i,
			"cut:s"		=>	\$cut,
			"scale:s"		=>\$scale,
			"out:s"	=>	\$out,
			) || &help;
&help unless ($i && $out);
if ($cut && $scale){
	print STDERR "\nWARNING: -cut or -scale, not both\n\n" ;
	exit;
}
sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: stat the length
    Usage:
        -i          <file>                         force
                    input format 
                               145
                               10000
                               125

        -cut        default [500bp]
        -scale       [100,200,300]
        -range       [0,200000]
        -out           <file>                         force
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
$cut ||=500;
my @a=split/,/,$scale if $scale;
my ($range1,$range2)=split/,/,$range if $range;
open(IN,$i) or die $!;
my %hash;my $total;
GO:while (<IN>) {
	chomp;
	if ($range1) {
		next if $_ <  $range1;
	}
	if ($range2) {
		next if $_ >= $range2;
	}
	if (defined $scale) {
		for (my $i=0;$i<@a;$i++) {
			unless (defined $a[$i+1]){
				if ($_ >= $a[$i]) {
					$hash{">$a[$i]"} ++;
					$total++;
					next GO;
				}
			}elsif ($_>= $a[$i] && $_ < $a[$i+1]) {
				$hash{"$a[$i]-$a[$i+1]"} ++;
				$total ++;
				next GO;
			}
		}
		next;
	}
	for (my $i=0;$i<1900000;$i +=$cut) {
		if ($_ >$i && $_ < $i+$cut) {
			$hash{$i+$cut} ++;
			$total ++;
			next GO;
		}
	}
}
open (OUT,">$out")or die $!;
print OUT "length\tnum\tratio\n";
if ($scale) {
	foreach my $length (sort keys %hash) {
		print OUT join"\t",$length,$hash{$length},$hash{$length}/$total;
		print OUT "\n";
	}
}else{
	foreach my $length (sort{$a <=> $b } keys %hash) {
		print OUT join"\t",$length,$hash{$length},$hash{$length}/$total;
		print OUT "\n";
	}
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

