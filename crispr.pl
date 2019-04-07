#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($bamlist,$out,$dsh,$sgrna,$fa,$ann,$sid,$step,$stop);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"bam|bamlist:s"=>\$bamlist,
	"out|output:s"=>\$out,
	"dsh|dshell:s"=>\$dsh,
	"sg|sgrna:s"=>\$sgrna,
	"f|fa:s"=>\$fa,
	"sid|sampleid:s"=>\$sid,
	"a|ann:s"=>\$ann,
	"se|step:s"=>\$step,
	"so|stop:s"=>\$stop,
			) or &USAGE;
&USAGE unless ($fa and $out and $dsh);
` mkdir -p $dsh ` if (!-d $dsh);
`mkdir $out `if (!-d $out);
$bamlist=ABSOLUTE_DIR($bamlist);
$out=ABSOLUTE_DIR($out);
$dsh=ABSOLUTE_DIR($dsh);
$sgrna=ABSOLUTE_DIR($sgrna);
$fa=ABSOLUTE_DIR($fa);
if ($ann) {
	$ann=ABSOLUTE_DIR($ann);
}
$step||=1;
$stop||=-1;
open LOG,">$out/$dsh/crispr.$BEGIN_TIME.log";
if ($step == 1) {
	print LOG "########################################\n";
	print LOG "risearch\n"; my $time=time();
	print LOG "########################################\n";
	open SH,">$dsh/sgRNA1.sh";
	print SH "cd $out && risearch2.x -c $fa -o $out/ref.suf && ";
	print SH "risearch2.x -q $sgrna -i $out/ref.suf -s 1:20 -m 6:0 -e 10000 -l 0 --noGUseed -p3 -t 8 && ";
	print SH "perl $Bin/bin/sgrna.region.pl -i $out/risearch_sgrna.out.gz -o $out/sgRNA.region -sgr $sgrna \n";
	close SH;
	my $job = "qsub-slurm.pl --Resource mem=50G --CPU 8 $dsh/sgRNA1.sh";
	print "$job\n";
	`$job`;
	print LOG "########################################\n";
	print LOG "Done and elapsed time : ",time()-$time,"s\n";
	print LOG "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 2) {
	print LOG "########################################\n";
	print LOG "CRISPRessoWGS\n"; my $time=time();
	print LOG "########################################\n";
	open SH,">$dsh/sgRNA2.sh";
	open IN,$bamlist;
	while (<IN>) {
		chomp;
		my ($sam,$bam)=split/\s+/,$_;
		print SH " CRISPRessoWGS -b $bam -f $out/sgRNA.region -r $fa -n $sam -o $out --save_also_png --keep_intermediate ";
		if ($ann) {
			print SH " --gene_annotations $ann\n";
		}else{
			print SH "\n";
		}
	}
	close IN;
	close SH;
	my $job = "qsub-slurm.pl --Resource mem=20G --CPU 4 $dsh/sgRNA2.sh";
	print "$job\n";
	`$job`;
	print LOG "########################################\n";
	print LOG "Done and elapsed time : ",time()-$time,"s\n";
	print LOG "########################################\n";
	$step++ if ($step ne $stop);
}
#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
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
		warn "Warning just for file and dir \n$in";
		exit;
	}
	chdir $cur_dir;
	return $return;
}

sub USAGE {#
        my $usage=<<"USAGE";
Contact:        meng.luo\@majorbio.com;
Script:			$Script
Description:
	fq thanslate to fa format
	eg:
	perl $Script -i -o -k -c

Usage:
  Options:
 -bam bamlist filename
	-out output dir
	-dsh work shell
	-sg sgrna.fa formate
	-fa ref.fa 
	-sid sample id name (default was analysis all sample)
	-ann ann.summary (pop.summary)
  -h         Help

USAGE
        print $usage;
        exit;
}
