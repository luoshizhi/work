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
use List::Compare;
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

my ($out,$bed,$block_file,$target_file,$aligns);
GetOptions(
			"h|?"		=>	\&help,

			"out:s"	=>	\$out,
			"bed:s"	=>	\$bed,
			"block:s"	=>	\$block_file,
			"target:s"	=>	\$target_file,
			"aligns:s"	=>	\$aligns,
			) || &help;
&help unless ($out && $bed && $block_file && $target_file && $aligns ) ;

sub help
{
	print <<"	Usage End.";
    Description:
        Writer  : $Writer
        Data    : $Data
        Version : $ver
        function: ......
    Usage:
        -out           <file>                         forced
        -bed           <bed_file>                     forced
        -block         <target_block_file>                   forced
        -target        <target_file>                  forced
        -aligns        <aligns_file>                  foeced
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
my %pos;my %target;my %block;my %list;
open (BED,$bed) or die;
while (<BED>) {
	chomp;
	my ($chr,$star,$end,$id)=split;
	($star,$end)=sort {$a <=> $b}($star,$end);
	@{$pos{$id}}=($chr,$star,$end);
}
close(BED);
open(TARGET,$target_file) or die $!;
while (<TARGET>) {
	chomp;
	s/\s+//g;
	@{$list{$_}}=@{$pos{$_}};
}
close (TARGET);

my @array;
open(BLOCK,$block_file) or die $!;
while (<BLOCK>) {
	chomp;
	next if /^\#/;
	next if /^\s*$/;
	my (undef,@block_units)=split/\t+/,$_;
	my @block_temp;
	for (my $i=0;$i<@block_units;$i++) {
		next if $block_units[$i] eq ".";
		my @temp=split/;/,$block_units[$i];
		push @block_temp,@temp;
		my %redu;
		@redu{@block_temp}=undef;
		@block_temp=keys %redu;
	}
	next if (@block_temp<=1);
	push @array,[@block_temp];
}

@array=&Redu(\@array); # 将block存于二维数组，去冗余block，将冗余block合并，取并集；

for (my $i=0;$i<@array;$i++) {
	for (my $j=0;$j<@{$array[$i]};$j++) {
		@{$block{$array[$i][$j]}}=@{$array[$i]};
	}
}
my $output;
open (ALI,$aligns) or die $!;
$/="## Alignment";
while (<ALI>) {
	chomp;
	next if (/^\#/);
	next if (/^\s*$/);
	my ($head,@line)=split/\n/,$_;
	my ($chr1,$chr2)=$head=~/(\w+)&(\w+)/;

	my @region_1;my @region_2;my $flag=0;my $gene1;my $gene2;
	for (my $i=0;$i<@line;$i++) {
		my ($pair_1,$pair_2)=(split/\t+/,$line[$i])[1,2];
		push @region_1,$pair_1;
		if (exists $block{$pair_1} && exists $block{$pair_2}){
			$gene1=$pair_1;$gene2=$pair_2;
		}
		push @region_2,$pair_2;
	}
	
	next unless (defined $gene1 && defined $gene2);
	my($region_1_star,$region_1_end,$chro1)=&range_region(@region_1);
	my($region_2_star,$region_2_end,$chro2)=&range_region(@region_2);
	my @target1;my @target2;
	for (my $i=0;$i<@{$block{$gene1}};$i++) {
		if (exists $list{$block{$gene1}->[$i]}) {
			my $target_gene1=$block{$gene1}->[$i];
			if ($pos{$target_gene1}->[0] eq $chro1 && $pos{$target_gene1}->[1]>=$region_1_star && $pos{$target_gene1}->[2]<=$region_1_end) {
				push @target1,$target_gene1;
			}
		}
	}
				
	for (my $i=0;$i<@{$block{$gene2}};$i++) {
		if (exists $list{$block{$gene2}->[$i]}) {
			my $target_gene2=$block{$gene2}->[$i];
			if ($pos{$target_gene2}->[0] eq $chro2 && $pos{$target_gene2}->[1]>=$region_2_star && $pos{$target_gene2}->[2]<=$region_2_end) {
				push @target2,$target_gene2;
			}
		}
	}
	if (@target1>=1 && @target2>=1) {
		$output .= "chr\t$chr1,$chr2\n";
		$output .=  "region\t$chr1\t$region_1_star\t$region_1_end\t$chr2\t$region_2_star\t$region_2_end\n";
		foreach my $id1 (@target1) {
			$output .=  "pos\t$pos{$id1}->[0]\t$pos{$id1}->[1]\t$pos{$id1}->[2]\t$id1\n";
		}
		foreach my $id2 (@target2) {
			$output .=  "pos\t$pos{$id2}->[0]\t$pos{$id2}->[1]\t$pos{$id2}->[2]\t$id2\n";
		}
	}

}

open (OUT,">$out") or die $!;
	print OUT $output;
close OUT;


sub Redu() #对二维数组有效，将冗余数组合并，取并集；
{
	my ($index) =@_;
	my @block=@{$index};
	my $redu1=@block;
	@block=&Redu_Once(\@block);
	my $redu2=@block;
	while (1) {
		if ($redu1==$redu2) {
			return @block;
		}else{
			$redu1=@block;
			@block=&Redu_Once(\@block);
			$redu2=@block;
		}
	}
}

sub Redu_Once()#将冗余block合并一次。取并集，可能还存在冗余block；
{
	my ($index) =@_;
	my @block=@{$index};
	die "Please check the block file that whether the blocks number were more than 2 !!" if @block<=1;
	my $flag_i=0;
	for (my $i=0;$i<@block-1;$i++) {
		if ($flag_i==1){
			$flag_i=0;
			$i=$i-1;
		}
		my $flag_j=0;
		for (my $j=$i+1;$j<@block ;$j++) {
			my @list_i=@{$block[$i]};
			if ($flag_j==1){
				$j=$j-1;
				$flag_j=0;
			};

			my @list_j=@{$block[$j]};
			my $lc = List::Compare->new(\@list_i, \@list_j);
			my @intersection = $lc->get_intersection;  #交集
			my @union = $lc->get_union;#并集
			if (@intersection >=1) {
				@{$block[$i]}=@union;
				$flag_i=1 if ($j==$i+1);
				$flag_j=1;
				splice @block,$j,1;
			}
		}
	}
	return @block;
}

sub range_region(){
	my @region=@_;
	my @star;my @end;
	for(my $i=0;$i<@region-1;$i++){
		if ($pos{$region[$i]}->[0] ne $pos{$region[$i+1]}->[0]) {
			die "the chr is not the same in the aligns regions\n";
		}
	}
	my $chr=$pos{$region[0]}->[0];
	for (my $i=0;$i<@region;$i++) {
		push @star,$pos{$region[$i]}->[1];
		push @end,$pos{$region[$i]}->[2];
	}
	my($star)=sort {$a <=> $b}@star;
	my($end)=sort {$b <=> $a}@end;
	return($star,$end,$chr);
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

