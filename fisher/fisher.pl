#!/usr/bin/perl -w
# Copyright (c) BRD 2015/12/29
# Writer:         Luosz <luosz@biobreeding.com.cn>
# Program Date:   2015/12/29.

use GD;
use Cwd;
use strict;
use Getopt::Long;
use FindBin qw/$Bin $Script/;
use Data::Dumper;
use File::Basename qw(basename dirname);
use Text::NSP::Measures::2D::Fisher::right;

my $programe_dir=basename($0);
my $path=dirname($0);

#######################################################################################

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------

my ($in,$out);
GetOptions(
			"h|?"		=>	\&help,
			"in:s"		=>	\$in,
			"out:s"	=>	\$out,
			) || &help;
&help unless ($in  );

sub help
{
	print <<"	Usage End.";
    Description:
        function: ......
    Usage:
        -in          <file>                         force
        -out           <file>                         force
        -h          Help document

	Usage End.
	exit;
}
# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------

################
	$, = undef;
	$\ = undef;
	################ Fisher's exact test #############

	foreach my $stat_go (glob "$in/*.xls") {
		open (IN,"$stat_go") || die "Can't open $stat_go,$!\n";
		$stat_go =~s/.xls$//;
		open (OUT,">$stat_go.stat") || die "Can't creat $stat_go.stat,$!\n";
		$,="\t";
		$\= "\n";
		my (%hash,%new,$i);
		print OUT "\#".'Gene_Ontology_term','Cluter_frequency','Genome_frequency','P-value','Corrected_P-value';
		while (<IN>) {
			#next unless $. > 3;
            next if (/^#/);
			chomp;
			my ($term,$m,$M,$n,$N) = (split /\t/,$_)[0..4];
			my $p_value = &hyper($m,$M,$n,$N);
			my $m_ratio = "$m out of $n ".100 * $m / $n.'%';
			my $M_ratio = "$M out of $N ".100 * $M / $N.'%';
			$hash{$term}{name} = $term;
			$hash{$term}{p_value} = $$p_value;
			$hash{$term}{p_corr} = $$p_value;
			$hash{$term}{ratio}="$m_ratio\t$M_ratio";
			$i+=1;
		}
		for (sort {$hash{$a}->{p_value} <=> $hash{$b}->{p_value}}  keys %hash) {	#tag 用二级键值排序,避免新建哈希
			$hash{$_}{p_corr} = ($hash{$_}{p_value} * $i >1) ? 1 : $hash{$_}{p_value} * $i;
			print OUT $hash{$_}->{name},$hash{$_}->{ratio},$hash{$_}{p_value},$hash{$_}->{p_corr};
		}		undef $,;
		undef $\;
		close IN;
		close OUT;
		%hash = ();
		%new = ();
	#	`rm $stat_go.xls`;
	}
sub hyper{ #calculate  Fisher's exact test
	my ($n11,$n1p,$np1,$npp)=@_;
	my ($out,$errorCode,$right_value);
	$right_value = calculateStatistic(
		n11=>$n11,
		n1p=>$n1p,
		np1=>$np1,
		npp=>$npp
	);
	if( ( $errorCode = getErrorCode() ) ) {
		$out = $errorCode." - ".getErrorMessage();
	}
	else {
		$out = $right_value;
	}
	return \$out;
}