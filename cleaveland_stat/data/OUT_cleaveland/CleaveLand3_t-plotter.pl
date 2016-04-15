## CleaveLand 3.0.1
## CleaveLand3_t-plotter.pl
## Mike Axtell
## August 26, 2011
## Penn State Universtiy
## mja18@psu.edu

# version difference: 3.0.1 fixes an error in tabulating transcriptome data in CleaveLand3_map2dd.pl
# thanks to Jan vaan Harst for pointing this out!

use Getopt::Std;

## define a usage statement
$usage = "$1 : make a t-plot from a degradome results file, using R\n" . 
    "-f : Input file\.  This is a plain text file output by CleaveLand3_analysis\.pl giving details of a single sliced target\n" . 
    "-o : Name of output file.  This is the PDF that will be generated\.  Please remeber the \.pdf extension\.\n";

getopt('fo');

## ensure input
unless((-r $opt_f) and  ## file has to be readbale
       ($opt_f =~ /--\S+--\S+_degradome\.txt/)) {  ## this is the expected naming format for the input files
    die "Invalid input file -f \n$usage\n";
}
## report on the session
print STDERR `date`;
print STDERR `hostname`;
print STDERR `pwd`;
print STDERR "$0\n";
print STDERR "Version 3\.0\.1\n";
print STDERR "-f : Input file: $opt_f\n";
print STDERR "-o : Output pdf file: $opt_o\n";

## get data
open(IN, "$opt_f");
@all_data = <IN>;
close IN;

## parse
foreach $line (@all_data) {
    chomp $line;
    if($line =~ /category=(\S+),/) {
	$category = $1;
    }
    if($line =~ /p-value=(\S+),/) {
	$pval = $1;
    }
    if($line =~ /cleavage_site=(\d+)/) {
	$csite = $1;
    }
    if($line =~ /query=(\S+),/) {
	$query = $1;
    }
    if($line =~ /target=(\S+),/) {
	$target = $1;
    }
    if($line =~ /score=(\S+),/) {
	$score = $1;
    }
    if($line =~ /range=(\S+),/) {
	$range = $1;
    }
    if($line =~ /size=(\d+)$/) {
	$tx_size = $1;
	
	## initialize hash and trakcer
	%positions = ();
	$max_y = 0;
	for($i = 1; $i <= $tx_size; ++$i) {
	    $positions{$i} = 0;
	}
	
	## activate tallying part of script, everything below the size= line is the data
	$tally = 1;
    }
    if(($tally) and
       ($line =~ /^\d/)) {  
	@fields = split ("\t", $line);
	$pos = $fields[0];
	$raw = $fields[1];
	$positions{$pos} = $raw;
	
	if($raw > $max_y) {
	    $max_y = $raw;  ## this information is needed for plotting
	}
    }
}

## write a temp file readable by R
$temp_file = "CleaveLand3_t-plotter_tempfile\.txt";
open(TEMP, ">$temp_file");
## print a header
print TEMP "Position\tNonSite\tSite\n";
## output the data
for($i = 1; $i <= $tx_size; ++$i) {
    print TEMP "$i\t";
    if($i == $csite) {
	print TEMP "0\t$positions{$i}\n";  ## this is the cleavave site peak
    } else {
	print TEMP "$positions{$i}\t0\n";  ## this is for all of the other data
    }
}
close TEMP;

## ylim is 10% higher than max
$ylim = (int(1.1 * $max_y)) + 1;  


## open another tempfile, this one for the R script
$r_temp = "CleaveLand3_t-plotter_tempfileR\.txt";
open(R, ">$r_temp");
my $mtext=undef;
my @query=split/\./,$query;
for(my $i=0;$i<@query;$i++){
	my $j=$i+1;
	$mtext .="mtext\(\"$query[$i]\",adj=1,line=-$j\)\n"
}

## write the R script
print R "data <- read\.table\(\"$temp_file\", header=TRUE\)\n";  ## read in the data
print R "pdf\(file=\"$opt_o\"\)\n";  ## opens the pdf file
print R "plot\(data\$Position, data\$Site, ylim=c\(0,$ylim\), ylab=\"Reads\", xlab=\"$target position \(nts\)\",";
print R "main=\"$target at nt $csite\", type=\"l\", col=\"red\"\)\n";
print R "lines(data\$Position, data\$NonSite, type=\"l\"\)\n";
print R "mtext\(\"alignment score=$score , category=$category , p=$pval\"\)\n";
print R "$mtext";
print R "legendTxt <- c\(\"Cleavage Site $csite\",\"All Other Sites\"\)\n";
print R "legend\(\"topleft\", legend=legendTxt, col=c\(\"red\",\"black\"\), lty=c\(1,1\), cex=0.75\)\n";
print R "dev\.off\(\)\n";
close R;


## execute the R script
system ("R --vanilla --file=\"$r_temp\"");

## clean up the temp files

#system ("rm $temp_file");
#system ("rm $r_temp");



