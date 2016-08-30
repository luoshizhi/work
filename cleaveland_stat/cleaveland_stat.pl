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

my ($id,$od);
GetOptions(
			"h|?"		=>	\&help,
			"id:s"		=>	\$id,
			"od:s"	=>	\$od,
			) || &help;
&help unless ($id  && $od);

sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: ......
    Usage:
        -id          <file>                         force
        -od           <file>                         force
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
my @file=glob "$id/*txt";
#print Dumper @file;

mkdir "$od" if !-d $od;
my %gene;my %cleave_num;my %miRNA;
for(my $i=0;$i<@file;$i++){
	open (IN,"$file[$i]") or die $!;
	my $category=undef;
	my $query=undef;
	my $target=undef;
	while (<IN>){
		chomp;
		if (/category=(\d+?),/){
			$category=$1;
			print "$category";
		}
		if (/query=(.+?),/){
			$query=$1;
		}
		if (/target=(.+?),/) {
			$target=$1;
		}
		next unless ( $query && $target);
		$gene{$category}{$target}=undef;
		if (/<<</) {
			$cleave_num{$category}++;
		}
		
		$miRNA{$category}{$query}=undef;
	}
	close IN;
	my $Cdir="$od/Category${category}_Tplot";
	mkdir "$Cdir" if !-d "$Cdir";
	`cp $file[$i] $Cdir `;
	my $txt=(split/\//,$file[$i])[-1];
	my $pdf=(split/\//,$file[$i])[-1];
	$pdf =~s/txt/pdf/;
	print "perl $Bin/CleaveLand3_t-plotter.pl -f $Cdir/$txt -o  $Cdir/$pdf ";
	`perl $Bin/CleaveLand3_t-plotter.pl -f $Cdir/$txt -o  $Cdir/$pdf `;
}


open (OUT,">$od/Cleavage_stat.xls") or die $!;
print OUT "#Type\tPredicted_Sites\tGenee\tmiRNAs\tCleavage_Events\n";
my $tgene;
my $tmiRNA;
my $tcleave;
foreach my $type(sort keys %gene){
	my $gene=undef;
	my $miRNA=undef;
	my $cleave=undef;
	foreach my $key(sort keys %{$gene{$type}}){
		$gene++;
		$tgene++;
	}
	foreach my $key(sort keys %{$miRNA{$type}}){
		$miRNA++;
		$tmiRNA++;
	}
	$cleave=$cleave_num{$type};
	$tcleave+=$cleave_num{$type};
	print OUT "Category$type\t$gene\t$gene\t$miRNA\t$cleave\n";
}

print OUT "Total\t$tgene\t$tgene\t$tmiRNA\t$tcleave\n";;




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

