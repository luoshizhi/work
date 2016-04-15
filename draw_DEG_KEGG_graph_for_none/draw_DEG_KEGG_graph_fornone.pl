#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Encode;
use Spreadsheet::WriteExcel;
use Spreadsheet::ParseExcel;  
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $BEGIN_TIME=time();
my $version="1.0.0";
#######################################################################################

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($id,$deg,$key,$od);
GetOptions(
				"help|?" =>\&USAGE,
				"id:s"=>\$id,
				"deg:s"=>\$deg,
				"k:s"=>\$key,
				"od:s"=>\$od,
				) or &USAGE;
&USAGE unless ($id and $deg and $key and $od);

mkdir $od unless -d $od;
$od=&ABSOLUTE_DIR($od);
my ($path,$ko);
opendir (DH,$id) || die "cannot open the $id,$!\n";
for my $file (readdir DH) {
	$path      = $file if ($file =~ /Kegg\.path/);
	$ko        = $file if ($file =~ /Kegg\.ko/);
}
if (!defined $path || !defined $ko) {
	print STDERR "$id has no Kegg.ko or Kegg.pathway file,please check!\n";
	die;
}

my $kegg_enrich="perl $Bin/KeggGo_enrich_map_web.none.pl -d $deg -k $key -i $id -o $od -func kegg";
my $enrich_plot="perl $Bin/kegg_enrichment_plot.pl -enrich_file $od/pathway/kegg_enrichment/$key.KEGG.stat -od $od/Graph -key $key";
my $kegg_histogram="perl $Bin/draw_KEGG_histogram.pl --ipf $od/pathway/kegg_enrichment/$key.KEGG.xls --opd $od/pathway/kegg_enrichment/ --prf $key.KEGG";
&run($kegg_enrich);
&run($enrich_plot);
&run($kegg_histogram);

#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################

# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------
################################################################################################################

sub ABSOLUTE_DIR{ #$pavfile=&ABSOLUTE_DIR($pavfile);
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

################################################################################################################

sub max{#&max(lists or arry);
	#求列表中的最大值
	my $max=shift;
	my $temp;
	while (@_) {
		$temp=shift;
		$max=$max>$temp?$max:$temp;
	}
	return $max;
}

################################################################################################################

sub min{#&min(lists or arry);
	#求列表中的最小值
	my $min=shift;
	my $temp;
	while (@_) {
		$temp=shift;
		$min=$min<$temp?$min:$temp;
	}
	return $min;
}

################################################################################################################

sub revcom(){#&revcom($ref_seq);
	#获取字符串序列的反向互补序列，以字符串形式返回。ATTCCC->GGGAAT
	my $seq=shift;
	$seq=~tr/ATCGatcg/TAGCtagc/;
	$seq=reverse $seq;
	return uc $seq;			  
}

################################################################################################################

sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

sub run()
{
	my $cmd=shift;
	print "[".&GetTime."] $cmd\n";
	my $run = system($cmd);
	if ($run !=0) {
		print "Error: command fail: $cmd";
		exit(1);
	}
	print "[".&GetTime."] done\n";
	return;
}

sub USAGE {#
	my $usage=<<"USAGE";
ProgramName:
Version:	$version
Contact:	Luosz<luosz\@biobreeding.com.cn> 
Program Date:   2015.12.25
Usage:
  Options:
  -id     <dir>  input anno dir,forced 
  
  -deg   <file>  deg file,forced 
  
  -k     <str>   keywords of output file,forced 
  
  -od    <file>  output dir,forced 
  
  -h         Help

USAGE
	print $usage;
	exit;
}
