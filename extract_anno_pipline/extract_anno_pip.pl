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

my ($list,$id,$od,$key,$mRNA);
GetOptions(
			"h|?"	=>	\&help,
			"list:s"	=>	\$list,
			"id:s"	=>	\$id,
			"od:s"	=>	\$od,
			"key:s"	=>	\$key,
			"mRNA:s"	=>	\$mRNA,
			) || &help;
&help unless ($list &&  $od && $key && $mRNA);

sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: ......
    Usage:
        -list        <file>                          forced
        -id          <dir>  include  (id/02.gene-annotation  id/Result)  forced
        -od          <dir>                           forced
        -key         <str>  key                      forced
        -mRNA                                        forced
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
mkdir $od if !-d $od;
open(LIST,$list) or die $!;
my %gene;
while (<LIST>) {
	chomp;
	$gene{$_}=1;
}


############### nr.anno.txt #########

my ($nr)=glob "$id/02.gene-annotation/*nr.blast.tab.best.anno";
my $nr_out="$od/$key.nr.anno.txt";
&extract_anno($nr,\%gene,$nr_out);

my ($cog)=glob "$id/02.gene-annotation/*.Cog.class";
my $cog_out="$od/$key.Cog_class.txt";
&extract_anno($cog,\%gene,$cog_out);

my ($kog)= glob "$id/02.gene-annotation/*.Kog.class";
my $kog_out="$od/$key.Kog_class.txt";
&extract_anno($kog,\%gene,$kog_out);

my ($Pfam_tab)=glob "$id/02.gene-annotation/*.Pfam.align.tab";
my $Pfam_tab_out="$od/$key.anno.details";
&extract_anno($Pfam_tab,\%gene,$Pfam_tab_out);

my ($Pfam_anno)=glob "$id/02.gene-annotation/*.Pfam.align.anno";
my $Pfam_anno_out="$od/$key.Pfam.anno.txt";
&extract_anno($Pfam_anno,\%gene,$Pfam_anno_out);

my ($Swissprot_anno)=glob "$id/02.gene-annotation/*.Swissprot.blast.tab.best.anno";
my $Swissprot_anno_out="$od/$key.Swissprot.anno.txt";
&extract_anno($Swissprot_anno,\%gene,$Swissprot_anno_out);


my ($kegg)=glob "$id/02.gene-annotation/*.Kegg.blast.tab.best";
my $kegg_temp="$od/kegg.temp";
&extract_anno($kegg,\%gene,$kegg_temp);
`perl $Bin/bin/kegg_tab2path_ko.pl -tab $kegg_temp -od $od -key $key.Kegg && rm $kegg_temp` if defined $kegg;

my ($nt)=glob "$id/02.gene-annotation/*.nt.blast.tab.best.anno";
my $nt_out="$od/$key.nt.anno.txt";
&extract_anno($nt,\%gene,$nt_out);

my ($TrEMBL)=glob "$id/02.gene-annotation/*.TrEMBL.blast.tab.best.anno";
my $TrEMBL_out="$od/$key.TrEMBL.anno.txt";
&extract_anno($TrEMBL,\%gene,$TrEMBL_out);


my ($GO_anno) =glob "$id/Result/*.annot";
my $GO_anno_out="$od/$key.annot";
&extract_anno($GO_anno,\%gene,$GO_anno_out);
`perl $Bin/bin/extract_Blast2GO.pl -in $GO_anno_out -od $od -k $key ` if defined $GO_anno;



system "perl $Bin/bin/extract_anno_integrate.pl -gene $mRNA -id $od -od $od -key $key -list $list";

system "perl $Bin/bin/draw_GO_graph.pl -i $od/All_Database_annotation.xls -k $key -od $od" if defined $GO_anno;

system "perl $Bin/bin/draw_COG_graph.pl -i $od/All_Database_annotation.xls -k $key -od $od" if defined $cog;

system "perl $Bin/bin/draw_KOG_graph.pl -i $od/All_Database_annotation.xls -k $key -od $od" if defined $kog;

system "perl $Bin/bin/util/nr_pie_stat.pl -i $od/$key.nr.anno.txt -o $od/$key.nr.lib.stat -m 10" if defined $nr;


################# sub ################################



sub extract_anno(){
	my ($in,$list_hash,$out)=@_;
	return unless defined $in;
	open(IN,$in) or die $!;
	open(OUT,">$out") or die $!;
		while (my $line= <IN>) {
			chomp($line);
			if ($line=~/^\#/) {
				print OUT "$line\n";
				next;
			}
			my ($name)=split/\s+/,$line;
			if (exists $$list_hash{$name}) {
				print OUT "$line\n";
			}
	}
	close IN;
	close OUT;
	return;
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

