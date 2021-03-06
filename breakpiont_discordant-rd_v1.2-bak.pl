#!usr/bin/perl -w

use strict;
use Getopt::Long;
use PerlIO::gzip;

############################################################################################################################################
##########   This program is to detect HBV integration breakpoint using discordant paired reads in SOAP mapping results ####################
############################################################################################################################################

################### define the parameters of this program #################
my $usage="perl $0 -disc_read <se_se file> -bk <bk_file> -len <library length> -ods <output of discordant paired reads bk> -obk <output of new final bk>";
my ($disc, $bk_file, $ods, $len, $obk);
GetOptions (
	'disc_read=s' => \$disc,
	'ods=s' => \$ods,								# output of discordant paired reads bk
	'bk=s' => \$bk_file,
	'len=i' => \$len,								# library length
	'obk=s' => \$obk									# output of new final bk
);
die $usage if !$disc | !$ods | !$obk | !$bk_file | !$len;

######### read in the breakpoint file from step4 and associate with se_se file ##########
my %bk;
open BK,$bk_file or die "can't open $bk_file\n";
while (<BK>){
	next if /left_support/;										# skip the header line
	chomp;
	my ($chr,$pos)=(split /\s+/)[0,1];
	$bk{$chr}{$pos} = 1;										# record the breakpoint for subsequent use; "1" can be replaced by any character
}
close BK;

#################### read in the se_se file containing the discordant reads #####################
my %discordant;
if ($disc=~/.gz\b/){
    open DS,"gzip -dc $disc|" or die $!;
}else{
    open DS,"$disc" or die $!;
}


my %disc_bk; my %disc_bk_nosplit;
open ODS, ">$ods" or die $!;
print ODS "discordant_pos\tclosest_bk_in_split_reads\tdiscordant_read\n";
while(<DS>){
    chomp;
#    my ($chr,$start)=(split /\s+/)[1,2];													# $start is the alignment position of discordant reads on human genome
	my ($id, $chr, $start, $chain, $rlen)=(split /\s+/)[0, 1, 2, 3, 4];
	my $flag = 0;																			# define a flag for judgeing whether discordant_pos is close to a bk or not
	for my $pos (keys %{$bk{$chr}}){
        if($start<=$pos+$len && $start>=$pos-$len){
            print ODS "discordant_pos:$chr-$start\tclosest_bk_in_split_read:$chr-$pos\t$id\n";		# the bks detected in step4 are all derived from split reads
			my $pair_id = $id; $pair_id =~ s/\/\d//;
			push @{$disc_bk{"$chr\t$pos"}}, $pair_id;
			$flag = 1;
            last;
        }
    }
	if($flag == 0){																			# it is the situation that all breakpoints were not close to the discordant_pos
		my $pair_id = $id; $pair_id =~ s/\/\d//;
		print ODS "discordant_pos:$chr-$start\tno_close_bk_in_split_read\tnan\n";					# print out this situation
		push @{$disc_bk_nosplit{$chr}{$start}}, $pair_id;
	}
	<DS>;																					# skip one line
}
close DS;

my $tmp_count = 0; my $tmp_norm = 0;
open OBK, ">$obk" or die $!;
open BK,$bk_file or die "can't open $bk_file\n";
while (<BK>){
	chomp;
    if(/left_support/){                                     # treat the header line
		print OBK "ref\tpos\tleft_support\tright_support\tdiscordant_reads\ttotal_support\tnorm_left\tnorm_right\tnorm_discordant\tnorm_sum\tleft_reads_ID\tright_reads_ID\tdiscordant_reads\n";
		next;
	}
    my ($chr,$pos)=(split /\s+/)[0,1];
	my @a = split;
	if(not exists $disc_bk{"$chr\t$pos"}){
		print OBK "$a[0]\t$a[1]\t$a[2]\t$a[3]\tnan\t$a[4]\t$a[5]\t$a[6]\tnan\t$a[7]\t$a[8]\t$a[9]\tnan\n";
	}else{
		my $count = @{$disc_bk{"$chr\t$pos"}};																			# number of discordant reads supporting this bk
		my $reads_str = join (",", @{$disc_bk{"$chr\t$pos"}});															# discordant reads supporting this bk
		my $new_sum_sup = $a[4] + $count; 
		my $new_norm_sum = ($new_sum_sup/$a[4]) * $a[7];
		$new_norm_sum = sprintf ("%.3f", $new_norm_sum);
		print OBK "$a[0]\t$a[1]\t$a[2]\t$a[3]\t$count\t$new_sum_sup\t$a[5]\t$a[6]\tnan\t$new_norm_sum\t$a[8]\t$a[9]\t$reads_str\n";
		$tmp_norm = $new_norm_sum;									# for calculating norm sum for the bk supported by  discordant reads but not supported by  split reads
		$tmp_count = $new_sum_sup;									# for calculating norm sum for the bk supported by  discordant reads but not supported by  split reads
	}
}
close BK;

# merged bk of discordant reads
my $tmp_chr=''; my $tmp_pos=0;
for my $chr(keys %disc_bk_nosplit){									# merge all bk within a distance of library len into the first bk ranked by pos 
	for my $pos(sort{$a<=>$b} keys %{$disc_bk_nosplit{$chr}}){
		if(($chr eq $tmp_chr) && $pos<=$tmp_pos+$len && $pos>=$tmp_pos-$len){
			push @{$disc_bk_nosplit{$chr}{$pos}}, @{$disc_bk_nosplit{$tmp_chr}{$tmp_pos}};# merge the two bk and sup if they are within the length of library len
			delete $disc_bk_nosplit{$tmp_chr}{$tmp_pos};								  # delete the bk which has been merged into other bk
		}elsif($pos>$tmp_pos+$len || $pos<$tmp_pos-$len){
			$tmp_pos = $pos;
		}
	}
	$tmp_chr = $chr;
}
#close OBK;

for my $chr(keys %disc_bk_nosplit){
	for my $pos(keys %{$disc_bk_nosplit{$chr}}){								#print out merged bk of discordant reads
		my $count = @{$disc_bk_nosplit{$chr}{$pos}};
		my $new_norm_sum = ($count/$tmp_count) * $tmp_norm;
		$new_norm_sum = sprintf ("%.3f", $new_norm_sum);
		my $reads_str = join (",", @{$disc_bk_nosplit{$chr}{$pos}});
		print OBK "$chr\t$pos\tnan\tnan\t$count\t$count\tnan\tnan\t$new_norm_sum\t$new_norm_sum\tnan\tnan\t$reads_str\n";
	}
}
close OBK;

############################## subroutine #################################
sub medain{
	my @data = @_;
	return($data[int(@data/2)]);
}
