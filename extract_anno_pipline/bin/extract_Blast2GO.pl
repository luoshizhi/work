#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
#######################################################################################

my $notename=`hostname`;chomp $notename;

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($od,$Index,$in);
GetOptions(
				"help|?" =>\&USAGE,
				"od:s"=>\$od,
				"in:s"=>\$in,
				"k:s"=>\$Index,
				) or &USAGE;
&USAGE unless ($od and $Index and $in);

&MKDIR($od);
$od=&ABSOLUTE_DIR($od);

&MKDIR("$od/Blast2go");
my $blast2go="/share/nas2/genome/biosoft/blast2go/2.5"; #2014-12-08 ~ 
my $obo="/share/nas2/database/go/20151209/release20151209_go.obo";


############################################################################################################¥¶¿Ì.annot∫Õ.obo
	open (AN,"$in") or die $!;
	my (%Query,%GO);

	while (<AN>) {
		chomp;
		next if (/^$/);
		my ($query,$go_id)=(split/\t/,$_)[0,1];
		$Query{$query}{$go_id}=1;
		$GO{$go_id}{$query}=1;
	}
	close AN;

	my (%GO_Info, %GO_anno);
    open (OBO,$obo)||die "$!";
	$/="[Term]";
	while (<OBO>) {
		chomp;
		next if(/^$/);
		my @Term_info=split /\n+/,$_;
	    my (@go_ids,$go_name,$go_class,$anno);
		foreach (@Term_info) {
			if($_=~/^id: (.+)/ or /^alt_id: (.+)/){
				push @go_ids,$1;
            }elsif($_=~/^name: (.+)/){
				$go_name=$1;
			}elsif($_=~/^namespace: (.+)/){
				my $class=$1;
				if ($class=~/biological_process/) {
					$go_class="Biological Process";
				}
				if ($class=~/cellular_component/) {
					$go_class="Cellular Component";
				}
				if ($class=~/molecular_function/) {
					$go_class="Molecular Function";
				}
			}elsif($_=~/^def: \"(.+)\"/){
				$anno=$1;
                for my $go_id (@go_ids) {
                    $GO_Info{$go_id}{CLASS}=$go_class;
                    $GO_Info{$go_id}{NAME}=$go_name;
                    $GO_Info{$go_id}{ANNO}=$anno;
                    $GO_anno{$go_id}="$go_class: $go_name ($go_id);";
                }
			}
		}
	}
	$/="\n";
	close OBO;

	my %GO_Class_stat;
	my %GO_stat;
	open OUT1,">$od/$Index.GO.list.txt"||die"$!";
	open OUT2,">$od/$Index.GO.anno.txt"||die "$!";
	print OUT2 "#Gene\tGO_Anno\n";
	foreach my $gene (sort {$a cmp $b} keys %Query) {
		print OUT1"$gene\t";
		my @go_list=(keys %{$Query{$gene}});
		my $num=@go_list;
		print OUT2 "$gene\t$num\t";
		foreach my $go_id (sort {$a cmp $b} keys %{$Query{$gene}}) {
			if (exists $GO_anno{$go_id}) {
				print OUT1"$go_id\t";
				print OUT2 "$GO_anno{$go_id}\t";
				$GO_Class_stat{$GO_Info{$go_id}{CLASS}}++;
				$GO_stat{$GO_Info{$go_id}{CLASS}}{$GO_anno{$go_id}}{$gene}=1;
			}
		}
		print OUT1 "\n";
		print OUT2 "\n";
	}
	close OUT1;
	close OUT2;

	open OUT3,">$od/$Index.GO_tree.stat.xls"||die "$!";
	print OUT3"#GO_Function\tUnigene_number\tUnigene_ID\n";
	foreach my $go_class (sort keys %GO_Class_stat) {
		print OUT3 "$go_class\t$GO_Class_stat{$go_class}\n";
		foreach my $go_term (sort keys %{$GO_stat{$go_class}}) {
			my @genes=keys %{$GO_stat{$go_class}{$go_term}};
			my $gene_id_str=join ";",@genes;
			my $num=@genes;
			print OUT3 "$go_term\t$num\t$gene_id_str\n";
		}
	}

close (OUT3) ;


# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------
#######################################################################################

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

sub MKDIR
{ # &MKDIR($out_dir);
	my ($dir)=@_;
	rmdir($dir) if(-d $dir);
	mkdir($dir) if(!-d $dir);
}

sub Shell_qsub
{ # &Shell_qsub($sh,$qeue,$cpu,$shdir);
	my $sh = shift;
	my $qeue = shift;
	my $cpu = shift;
	my $shdir = shift;

	if ($notename=~/cluster/)
	{
		chdir $shdir;
		system "qsub-sge.pl --queue $qeue --reqsub -maxproc $cpu --independent $sh ";
	}
	else
	{
		chdir $shdir;
		system "ssh cluster qsub-sge.pl --queue $qeue --reqsub --maxproc $cpu --independent $sh " ;
	}
}

################################################################
sub USAGE {#
	my $usage=<<"USAGE";
ProgramName:
Version: $version
Contact: Luosz <luosz\@biobreeding.com.cn>
Program Date:   2015/12/29
Description:	This program is used to extract GO Annotation;
Usage:
                 Options:
                     -in <file.annot>      input file                                               forced;

                     -od <dir>      output file directory                                           forced;

                     -k <str>       out file prefix name                                            forced;

                     -h         Help

USAGE
	print $usage;
	exit;
}
