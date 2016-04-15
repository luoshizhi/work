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

my ($cDNA,$lncRNA,$od,$target);
GetOptions(
			"h|?"		=>	\&help,
			"c:s"		=>	\$cDNA,
			"l:s"	=>	\$lncRNA,
			"t:s"	=>	\$target,
			"od:s"	=>	\$od,
			) || &help;
&help unless ($cDNA  && $lncRNA && $target && $od);

sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: ......
    Usage:
        -c          <dir>          miRNA target cDNA dir                 force
        -l           <dir>         miRNA target lncRNA dir               force
        -t           <file>        lncRNA target cDNA  dir               force
        -od          <dir>          
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
open (TARGET,"$target") or die $!;
my %lncRNA_target;
while (<TARGET>){
	chomp;
	my($lnc,$lnc_t)=split;
	$lncRNA_target{$lnc}=$lnc_t;
}
close TARGET;
my @cDNA=glob "$cDNA/*";
my %miRNA_cDNA;
foreach my $c_file (@cDNA) {
	open (cDNA,"$c_file") or die $!;
	while (<cDNA>){
		chomp;
		if (/query=(.+?),\s*target=(.+?),/) {
			$miRNA_cDNA{$1}{$2}=undef;
			next;
		}
	}
}
close cDNA;

my @lncRNA=glob "$lncRNA/*";
my %miRNA_lncRNA;
my %lncRNA_miRNA;
foreach my $lnc_file (@lncRNA) {
	open (Lnc,"$lnc_file") or die $!;
	while (<Lnc>){
		chomp;
		if (/query=(.+?),\s*target=(.+?),/) {
			$miRNA_lncRNA{$1}{$2}=undef;
			$lncRNA_miRNA{$2}{$1}=undef;
		}
	}
	close Lnc;
}
my$od_miRNA="$od/miRNA_role";
`mkdir -p  $od_miRNA` if !-d $od_miRNA;
foreach my $miRNA(sort keys %miRNA_lncRNA){
	my $join="$miRNA -->\|\n";
	my $space=" " x (length($join)-2);
	if (exists $miRNA_cDNA{$miRNA}) {
		foreach my $cDNA1(sort keys %{$miRNA_cDNA{$miRNA}}){
			$join .="$space\| --> $cDNA1\n";
		}
	}
	foreach my $lncRNA1(sort keys %{$miRNA_lncRNA{$miRNA}}){
		if (exists $lncRNA_target{$lncRNA1}) {
			$join .="$space\| --> $lncRNA1 --> $lncRNA_target{$lncRNA1}\n";
		}else{
			$join .="$space\| --> $lncRNA1\n";
		}

	}
	open (OUT,">$od_miRNA/${miRNA}_target_net.txt") or die $!;
	print OUT $join;
}

my $od_lncRNA="$od/lncRNA_role";
`mkdir -p  $od_lncRNA` if !-d $od_lncRNA;
foreach my $lncRNA1(sort keys %lncRNA_miRNA ){
	my $join="";
	my $flag=0;
	foreach my $miRNA(sort keys %{$lncRNA_miRNA{$lncRNA1}}){
		my $space=" " x (16-length($miRNA));
		if ($flag==0) {
			if (exists $lncRNA_target{$lncRNA1}) {
				$join .="$miRNA$space -->|$lncRNA1 --> $lncRNA_target{$lncRNA1}\n";
			}else{
				$join .="$miRNA$space -->|$lncRNA1\n";
			}
			$flag=1;
		}else{
			$join .="$miRNA$space -->|\n";
		}
	}
	open (OUT,">$od_lncRNA/${lncRNA1}_net.txt") or die $!;
	print OUT $join;
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

