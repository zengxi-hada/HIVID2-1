#!usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Basename;
use PerlIO::gzip;

#####################################################################################################################################
### this program is to extract the paired reads which may contain virus DNA based on soap results for reads after timmomatics #######
#####################################################################################################################################

my $usage="perl $0 -hp <human soap PE> -hs <human soap SE> -hu <human soap unmap> -bp <HBV soap PE> -bs <HBV soap SE> -bu < HBV soap unmap> -pe < out PE_PE > -se <out SE_SE> -sb<out HBV_UN> -sh <out human_UN> -un <out UN_UN> -stat <out stat file> -f1 <read1> -f2 <read2> -o <read file dir> -filter <whether filter non-unique human alignment>\n";
my ($hu_pe,$hu_se,$hu_un,$hb_pe,$hb_se,$hb_un,$pe_pe,$se_se,$hbv_un,$human_un,$un_un,$stat,$read1,$read2,$out,$filter);
GetOptions (
        'hp=s'=>\$hu_pe,
        'hs=s'=>\$hu_se,
        'hu=s'=>\$hu_un,
        'bp=s'=>\$hb_pe,
        'bs=s'=>\$hb_se,
        'bu=s'=>\$hb_un,
        'pe=s'=>\$pe_pe,
        'se=s'=>\$se_se,
        'sb=s'=>\$hbv_un,
        'sh=s'=>\$human_un,
        'un=s'=>\$un_un,
        'stat=s'=>\$stat,
        'f1=s'=>\$read1,
        'f2=s'=>\$read2,
        'o=s'=>\$out,
	'filter!'=>\$filter,				# whether filter non-unique human alignment
);
die $usage if (!$hu_pe|!$hu_se|!$hu_un|!$hb_pe|!$hb_se|!$hb_un|!$pe_pe|!$se_se|!$hbv_un|!$human_un|!$un_un|!$stat);

my (%hupe,%huse,%huun,%hbpe,%hbse,%hbun);
($filter)?&read_pese($hu_pe,\%hupe,"human"):&read_pese($hu_pe,\%hupe,"0");
($filter)?&read_pese($hu_se,\%huse,"human"):&read_pese($hu_se,\%huse,"0");
&read_pese($hb_pe,\%hbpe,"0");
&read_pese($hb_se,\%hbse,"0");
&read_un($hu_un,\%huun);
&read_un($hb_un,\%hbun);

=h
for my $i(keys %hbun){
	print "$i\n";
}
=cut

my ($pe_pe_num,$pe_se_num,$pe_un_num)=(0,0,0);
my (%idpp,%idss,%idbu,%idhu,%iduu);

open OUT1, "|gzip > $pe_pe" or die $!;
open OUT2, "|gzip > $se_se" or die $!;
open OUT3, "|gzip > $hbv_un" or die $!;
open OUT4, "|gzip > $human_un" or die $!;
open OUT5, "|gzip > $un_un" or die $!;

for my $read_id(keys %hbpe){
	if (exists $hupe{$read_id}){
		print OUT1 "$read_id"."1\t",$hupe{$read_id}{"1"},"\n";
		print OUT1 "$read_id"."2\t",$hupe{$read_id}{"2"},"\n";
		my $hupechr=(split /\s+/,$hupe{$read_id}{"1"})[0];
		my $hbpechr=(split /\s+/,$hbpe{$read_id}{"1"})[0];
		$idpp{$read_id}="$hupechr"."_$hbpechr";
		delete $hupe{$read_id};
		$pe_pe_num++;
	}elsif(exists $huse{$read_id}){
		if (exists $huse{$read_id}{"1"}){
			print OUT1 "$read_id"."1\t",$huse{$read_id}{"1"},"\n";
			my $hupechr=(split /\s+/,$huse{$read_id}{"1"})[0];
			my $hbpechr=(split /\s+/,$hbpe{$read_id}{"1"})[0];
			$idpp{$read_id}="$hupechr"."_$hbpechr";
		}else{
			print OUT1 "$read_id"."2\t",$huse{$read_id}{"2"},"\n";
			my $hupechr=(split /\s+/,$huse{$read_id}{"2"})[0];
                        my $hbpechr=(split /\s+/,$hbpe{$read_id}{"2"})[0];
			$idpp{$read_id}="$hupechr"."_$hbpechr";

		}
		delete $huse{$read_id};
		$pe_se_num++;
	}elsif(exists $huun{$read_id}){
		delete $huun{$read_id};
		$pe_un_num++;
	}
	delete $hbpe{$read_id};
}

my ($se_pe_num,$se_se_num,$se_un_num)=(0,0,0);


for my $id (keys %hbse){
	if (exists $hupe{$id}){
		if (exists $hbse{$id}{"1"}){
			print OUT1 "$id"."2\t",$hupe{$id}{"2"},"\n";
			my $hupechr=(split /\s+/,$hupe{$id}{"2"})[0];
			my $hbpechr=(split /\s+/,$hbse{$id}{"1"})[0];
			$idpp{$id}="$hupechr"."_$hbpechr";
		}else{
			print  OUT1 "$id"."1\t",$hupe{$id}{"1"},"\n";
			my $hupechr=(split /\s+/,$hupe{$id}{"1"})[0];
			my $hbpechr=(split /\s+/,$hbse{$id}{"2"})[0];
			$idpp{$id}="$hupechr"."_$hbpechr";
		}
		delete $hupe{$id};
		$se_pe_num++;
	}elsif(exists $huse{$id}){
		if (exists $hbse{$id}{"1"}){
			if(exists $huse{$id}{"2"}){ print OUT2 "$id"."2\t",$huse{$id}{"2"},"\n"}else{ print OUT2 "$id"."2\t",$huse{$id}{"1"},"\n";}
			print OUT2 "$id"."1\t",$hbse{$id}{"1"},"\n";
			my $hupechr;
			if (exists $huse{$id}{"2"}){ $hupechr=(split /\s+/,$huse{$id}{"2"})[0]}else{ $hupechr=(split /\s+/,$huse{$id}{"1"})[0];}
			my $hbsechr=(split /\s+/,$hbse{$id}{"1"})[0];
			$idss{$id}="$hupechr"."_$hbsechr";
		}else{
			if (exists $huse{$id}{"1"}){ print OUT2 "$id"."1\t",$huse{$id}{"1"},"\n" }else{ print OUT2 "$id"."2\t",$huse{$id}{"2"},"\n";}
			print OUT2 "$id"."2\t",$hbse{$id}{"2"},"\n";
			my $hupechr;
			if (exists $huse{$id}{"1"}){ $hupechr=(split /\s+/,$huse{$id}{"1"})[0]}else{ $hupechr=(split /\s+/,$huse{$id}{"2"})[0];}
			my $hbsechr=(split /\s+/,$hbse{$id}{"2"})[0];
                        $idss{$id}="$hupechr"."_$hbsechr";
		}
		delete $huse{$id};
		$se_se_num++;
	}elsif(exists $huun{$id}){
		if (exists $hbse{$id}{"1"}){
			print OUT3 "$id"."2\t",$huun{$id}{"2"},"\n";
			print OUT3 "$id"."1\t",$hbse{$id}{"1"},"\n";
			my $hbsechr=(split /\s+/,$hbse{$id}{"1"})[0];
			$idbu{$id}="unmap_$hbsechr";
		}else{
			print OUT3 "$id"."1\t",$huun{$id}{"1"},"\n";
			print OUT3 "$id"."2\t",$hbse{$id}{"2"},"\n";
			my $hbsechr=(split /\s+/,$hbse{$id}{"2"})[0];
			$idbu{$id}="unmap_$hbsechr";
		}
		delete $huun{$id};
		$se_un_num++;
#	}else{
#			if(exists $hbse{$id}{"1"}){ print OUT3 "$id"."1\t",$hbse{$id}{"1"},"\n";}else{ print OUT3 "$id"."2\t",$hbse{$id}{"2"},"\n";}
#			my $hbsechr;
#			if(exists $hbse{$id}{"1"}){ $hbsechr=(split /\s+/,$hbse{$id}{"1"})[0];}else{ $hbsechr=(split /\s+/,$hbse{$id}{"2"})[0];}
#			$idbu{$id}="unmap_$hbsechr";
#			$se_un_num++;
	}
	delete $hbse{$id};
}

my ($un_pe_num,$un_se_num,$un_un_num)=(0,0,0);
for my $id(keys %hbun){
	if (exists $hupe{$id}){
		delete $hupe{$id};
		$un_pe_num++;
	}elsif(exists $huse{$id}){
		if (exists $huse{$id}{"1"}){
			print OUT4 "$id"."1\t",$huse{$id}{"1"},"\n","$id"."2\t",$hbun{$id}{"2"},"\n";
			my $husechr=(split /\s+/,$huse{$id}{"1"})[0];
			$idhu{$id}="$husechr"."_unmap";
		}else{
			print OUT4 "$id"."2\t",$huse{$id}{"2"},"\n","$id"."1\t",$hbun{$id}{"1"},"\n";
                        my $husechr=(split /\s+/,$huse{$id}{"2"})[0];
                        $idhu{$id}="$husechr"."_unmap";
		}
		delete $huse{$id};
		$un_se_num++;
	}elsif(exists $huun{$id}){
		print OUT5 "$id"."1\t",$huun{$id}{"1"},"\n$id"."2\t",$hbun{$id}{"2"},"\n";
		$un_un_num++;
		$iduu{$id}="unmap_unmap";
		delete $huun{$id};
	}
	delete $hbun{$id};
}

close OUT1;
close OUT2;
close OUT3;
close OUT4;
close OUT5;

my $totail=$pe_pe_num+$pe_se_num+$pe_un_num+$se_pe_num+$se_se_num+$se_un_num+$un_pe_num+$un_se_num+$un_un_num;
open STAT,">$stat" or die $!;
print STAT "For paired reads after trimmomatic\n";
print STAT "\tPE\tSE\tUnmap\n";
my @PE=($pe_pe_num,$pe_se_num,$pe_un_num);
percent("PE",$totail,@PE);
my @SE=($se_pe_num,$se_se_num,$se_un_num);
percent("SE",$totail,@SE);
my @UN=($un_pe_num,$un_se_num,$un_un_num);
percent("Unmap",$totail,@UN);
print STAT "HBV percent\t";
print STAT $pe_pe_num+$pe_se_num+$pe_un_num+$se_pe_num+$se_se_num+$se_un_num,"(";
printf STAT "%0.2f",($pe_pe_num+$pe_se_num+$pe_un_num+$se_pe_num+$se_se_num+$se_un_num)/$totail*100;
print STAT "%)\n";
print STAT "effective Ratio\t";
printf STAT "%0.2f",($pe_pe_num+$pe_se_num+$se_pe_num+$se_se_num)/$totail*100;
print STAT "%\n";
print STAT "Human percent\t",$pe_pe_num+$pe_se_num+$se_pe_num+$se_se_num+$un_pe_num+$un_se_num,"(";
printf STAT "%0.2f",($pe_pe_num+$pe_se_num+$se_pe_num+$se_se_num+$un_pe_num+$un_se_num)/$totail*100;
print STAT "%)\n";
print STAT "Paired-Total\t$totail\n";					# how many pairs (one pair contains two reads)
close STAT;
sub percent{
        my ($head,$total,@data)=@_;
        print STAT "$head\t";
        for(@data){
                my $percent=100*$_/$total;
                print STAT "$_(";
                printf STAT  "%0.2f",$percent;
                print STAT "%)\t";
        }
        print STAT "\n";
}

die if (!$read1|!$read2|!$out);
open FQ1,"gzip -cd $read1|" or die "can't open $read1";
open FQ2,"gzip -cd $read2|" or die "can't open $read2";
`mkdir $out` if !-e $out && !-d $out;
die "can't mkdir $out " if !-e $out;
my $dir_pepe="$out/pe_pe";
my $dir_sese="$out/se_se";
my $dir_hbvun="$out/hbv_un";
my $dir_humanun="$out/human_un";
my $dir_unun="$out/un_un";
`mkdir $dir_pepe $dir_sese $dir_hbvun $dir_humanun $dir_unun` if !-d $dir_pepe|!-d $dir_sese|!-d $dir_hbvun|!-d $dir_humanun|!-d $dir_unun;
my $name_read1=basename ($read1);
my $name_read2=basename ($read2);
$name_read1=~s/.gz\b//;
$name_read2=~s/.gz\b//;

open PP1,">$dir_pepe/$name_read1" or die "can't open $dir_pepe/$name_read1";
open PP2,">$dir_pepe/$name_read2" or die "can't open $dir_pepe/$name_read2";
open SS1,">$dir_sese/$name_read1" or die "can't open $dir_sese/$name_read1";
open SS2,">$dir_sese/$name_read2" or die "can't open $dir_sese/$name_read2";
open HBVU1,">$dir_hbvun/$name_read1" or die "can't open $dir_hbvun/$name_read1";
open HBVU2,">$dir_hbvun/$name_read2" or die "can't open $dir_hbvun/$name_read2";
open HUMAN1,">$dir_humanun/$name_read1" or die "can't open $dir_humanun/$name_read1";
open HUMAN2,">$dir_humanun/$name_read2" or die "can't open $dir_humanun/$name_read2";
open UNUN1,">$dir_unun/$name_read1" or die "can't open $dir_unun/$name_read1";
open UNUN2,">$dir_unun/$name_read2" or die "can't open $dir_unun/$name_read2";

#$/="@";
#<FQ1>;
#<FQ2>;
while (<FQ1>){
        chomp (my $id_fq1 = $_);
		my $seq_fq1 = <FQ1>;
		my $line3_fq1 = <FQ1>;
		my $qual_fq1 = <FQ1>;
		chomp (my $id_fq2 = <FQ2>);
        my $seq_fq2 = <FQ2>;
        my $line3_fq2 = <FQ2>;
        my $qual_fq2 = <FQ2>;
        my @d=split;
        if (!$d[0]){print $_;next}
##      $d[0]=~s/[12]$//;
        if (exists $idpp{$d[0]}){
                print PP1 "@"."$idpp{$d[0]}"."$_";
                print PP2 "@"."$idpp{$d[0]}"."$fq2";
        }elsif(exists $idss{$d[0]}){
                print SS1 "@"."$idss{$d[0]}"."$_";
                print SS2 "@"."$idss{$d[0]}"."$fq2";
        }elsif(exists $idbu{$d[0]}){
                print HBVU1 "@"."$idbu{$d[0]}"."$_";
                print HBVU2 "@"."$idbu{$d[0]}"."$fq2";
        }elsif(exists $idhu{$d[0]}){
                print HUMAN1 "@"."$idhu{$d[0]}"."$_";
                print HUMAN2 "@"."$idhu{$d[0]}"."$fq2";
        }elsif(exists $iduu{$d[0]}){
                print UNUN1 "@"."$iduu{$d[0]}"."$_";
                print UNUN2 "@"."$iduu{$d[0]}"."$fq2";
        }
}
close SS1;
close SS2;
close PP1;
close PP2;
close HBVU1;
close HBVU2;
close HUMAN1;
close HUMAN2;
close UNUN1;
close UNUN2;

my $reads_assembly="/public/home/xzeng/bin/BGI_bin/HPV/norm_hpv/update/HZAU1/overlap_pair_trim.new";
my $merge="/public/home/xzeng/bin/BGI_bin/HPV/norm_hpv/update/HZAU1/margefa_qua.pl";
for ($dir_unun,$dir_humanun,$dir_hbvun,$dir_sese,$dir_pepe){
        open SH,">$_/reads_assembly.sh" or die "can't open $_/reads_assembly.sh\n";
        print SH "$reads_assembly -a $_/$name_read1 -b $_/$name_read2 -c $_/left_$name_read1 -d $_/left_$name_read2 -o $_/assembly.fa -q $_/assembly_quality -l 1000\nperl $merge -i $_/assembly.fa -q $_/assembly_quality -o $_/reads_assembly_mergefa_quality_$name_read1\n";
##		print SH "rm -f $_/$name_read1 $_/$name_read2 $_/left_$name_read1 $_/left_$name_read2 $_/assembly.fa $_/assembly_quality\n";
        close SH;
        my $read_assembly_inf=`sh $_/reads_assembly.sh`;
        open RD,">$_/read_assembly_information" or die "can't open $_/read_assembly_information\n";
        print RD "$read_assembly_inf\n";
        close RD;
}
	

sub read_pese{
	my ($soap_file,$hash,$ter)=@_;
	if($soap_file=~/.gz$/){
		open IN,"gzip -cd $soap_file|" or die "can't open $soap_file\n";
	}else{
		open IN,"$soap_file" or die "can't open $soap_file\n";
	}
	while(<IN>){
		chomp;
		my ($soap_id,$unq,$read_order,$chr,$align_pos)=(split /\s+/)[0,3,4,7,8];
		if($unq>1 and $ter eq "human"){						# filter non-uniq alignment
			next;
		}
		my $read_order_ts = ($read_order eq "a") ? "1" : "2";
		$$hash{$soap_id}{$read_order_ts}="$chr\t$align_pos";
	}
	close IN;
}

sub read_un{
	my ($soap_file,$hash)=@_;
	if($soap_file=~/.gz$/){
                open IN,"gzip -cd $soap_file|" or die "can't open $soap_file\n";
        }else{
                open IN,"$soap_file" or die "can't open $soap_file\n";
        }
	my ($id,$soap_un)=(0,0);
	while(<IN>){
		chomp;
		$_=~s/^>//;
		<IN>;
##		$_=~s/[12]$//;
		if ($_ eq $id){
			$$hash{$id}{"1"}=1;
			$$hash{$_}{"2"}=1;
		}
		$id=$_;
	}
	close IN;
}
