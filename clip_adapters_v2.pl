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

my ($in,$out,$clip3,$clip5);
GetOptions(
			"h|?"		=>	\&help,
			"in:s"		=>	\$in,
			"out:s"	=>	\$out,
			"clip3:s"	=>	\$clip3,
			"clip5:s"	=>	\$clip5,
			) || &help;
&help unless ($in  && $out);
&help unless ($clip3 or $clip5);
sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: ......
    Usage:
        -in            <fa>                       force
        -out           <file>                       force
        -clip5         <seq>                        option
        -clip3         <seq>                        option
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

my $clip3_prefix=undef;
my $clip5_prefix=undef;
$clip3_prefix=substr($clip3,0,10) if $clip3;
$clip5_prefix=substr($clip5,-10,10) if $clip5;
#print "$clip5_prefix\n";
#die;
$/=">";
open (FASTA, "<$in") or die "can not open $in\n";
open (OUT,">$out") or die "can not open $out\n";
<FASTA>;
while (<FASTA>) {
	chomp;
	s/\r//g;
	my ($id,$seq)=(split/\n/,$_,2);
	$seq=~s/\n//g;
	$seq=&remove_3adapter($seq,$clip3_prefix) if $clip3;
	$seq=&remove_5adapter($seq,$clip5_prefix) if $clip5;
	if ($seq) {
		print OUT ">$id\n$seq\n";
	}
}
$/="\n";


sub remove_3adapter{

    my($seq,$prefix)=@_;
    
    $seq=~tr/[acgtun\.]/[ACGTTNN]/;
    
    my $seq_clipped;
    
    if($seq=~/(\w+?)$prefix/){
	
	$seq_clipped=$1;

    }elsif($seq=~/^$prefix/){
	$seq_clipped=undef;
	return $seq_clipped;
    }
	else{
	
	my $finish=0;
	
	while(not $finish and (length($prefix)>1)){
	    
	    chop $prefix;
	    if($seq=~/(\w+)$prefix$/){
		
		$seq_clipped=$1;
		$finish=1;
	    }
	}
 
    }
    
    if(not $seq_clipped){
		$seq_clipped=$seq;
    }
	return $seq_clipped;
}


sub remove_5adapter{

    my($seq,$prefix)=@_;
    unless($seq ) {
		return $seq;
	}
    $seq=~tr/[acgtun\.]/[ACGTTNN]/;
    
    my $seq_clipped;
    
    if($seq=~/$prefix(\w+?)/ ){
	
	$seq_clipped=$1;

    }elsif($seq=~/$prefix$/ ){
		$seq_clipped=undef;
		return $seq_clipped;
    }
	else{
	
	my $finish=0;
	
	while(not $finish and (length($prefix)>2)){
	    
#	    chop $prefix;
		$prefix=~s/^.//;
	    if($seq=~/^$prefix(\w+)/){

		$seq_clipped=$1;
		$finish=1;
	    }
	}
 
    }
    
    if(not $seq_clipped){

	
	$seq_clipped=$seq;
    }
	return $seq_clipped;

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

