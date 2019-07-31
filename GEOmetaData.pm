package PGXDB::GEOmetaData;

use Data::Dumper;
use File::Copy;
use LWP::Simple;
use LWP::Protocol::https;

use PGXDB::Utilities;

require Exporter;
@ISA    =   qw(Exporter);
@EXPORT =   qw(
  pgxdb_geosoft_extract_ids_from_array
  pgxdb_GEO_GSMs_from_GPL
  pgxdb_GEO_GSM_metadata
  pgxdb_GEO_GSE_metadata
);

################################################################################
################################################################################
################################################################################

sub pgxdb_geosoft_extract_ids_from_array {

  my $lines    	=   shift;
  my $pre     	=   shift;

  if (! grep{ $pre eq $_ } qw(GPL GSE GSM)) {
    return  [ 'NA' ];
  }

  my @ids       =   grep{ /_id ?\= ?$pre\d+/ } @$lines;
	s/^.*?($pre\d+?)$/$1/ for @ids;
	s/^.*?($pre\d+?)[^\d]*?$/$1/ for @ids;

  if (@ids > 0) { return \@ids } else { return [ 'NA' ] }

}

################################################################################

sub pgxdb_GEO_GSMs_from_GPL {

=pod

=cut

  my $pgxdb     =   shift;

	my $i					=		0;
	my $gplNo			=		@{ $pgxdb->{platforms}->{selected} };

  for my $gpl ( grep{ /GPL/ } @{ $pgxdb->{platforms}->{selected} }) {

		$i++;

    my $url     =   $pgxdb->{config}->{urls}->{geosoftlink}.$gpl;
    my $file		=		$pgxdb->{paths}->{geotmpdir}.'/'.$gpl.'.geometa.soft';

    if (
      (! -f $file)
      ||
      $pgxdb->{parameters}->{forcegpl} =~ /y/i
    ) {
  		print "\n".'trying '.$gpl.' ('.$i.'/'.$gplNo.')';
  		my $status		=		getstore($url, $file);
  		print "\n!!! No file file be loaded from\n$url\n" unless is_success($status);
  	}

    if (! -f $file) {
      print 'No file was found at '.$file."\n";
      next;
    }

		my @lines;
		my $fCont 	=   q{};
		open	FILE, "$file" or die "No file $file $!";
		local 	$/;															# no input separator
		$fCont  		=	  <FILE>;
		close FILE;
		foreach (split(/\r\n?|\n/, $fCont)) { push @lines, $_ }

		my $ids   =   pgxdb_geosoft_extract_ids_from_array(\@lines, 'GSM');
		
		# OPT: only data for platforms with fewer than the "randno" random sample
		# number are returned. This is just a debugging feature (as the use of 
		# "randno" is supposed to be).
		if ($pgxdb->{parameters}->{randno} > 0) {
			if (@$ids > $pgxdb->{parameters}->{randno}) {
				next }}

		print " - ".@$ids." ids";

		foreach my $gsm (grep{ /^GSM\d+?$/ } @$ids){

			if (! grep { /^$gsm$/ } @{ $pgxdb->{samples}->{existing} } ) {
				$pgxdb->{samples}->{new}->{$gsm} = $gpl }
		}
  }

  return  $pgxdb;

}

################################################################################

sub pgxdb_GEO_GSM_metadata {

=pod

http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM487790&form=text

=cut

  my $pgxdb      =   shift;

	my $i					=		0;
	my $gsmNo			=		keys %{ $pgxdb->{samples}->{new} };
	
  for my $gsm (sort grep{ /GSM/ } keys %{ $pgxdb->{samples}->{new} }) {

		$i++;		
    my $url			=		$pgxdb->{config}->{urls}->{geosoftlink}.$gsm;
    my $file		=		$pgxdb->{paths}->{geotmpdir}.'/'.$gsm.'.geometa.soft';

    if (
      (! -f $file)
      ||
      $pgxdb->{parameters}->{forcegsm} =~ /y/i
    ) {
  		print "\n".'trying '.$gsm.' ('.$i.'/'.$gsmNo.')';
  		my $status			=		getstore($url, $file);
  		print "\n!!! No file file be loaded from\n$url\n" unless is_success($status);
  	}

    if (! -f $file) {
      print 'no file could be loaded: '.$file."\n";
      next;
    }

    $pgxdb->{samples}->{meta}->{$gsm}  =   {
			GSM         =>  $gsm,
			GSE         =>  'NA',
			GPL         =>  'NA',
			PMID        =>  'NA',
			geosoft_url =>  $url,
			geosoft_local =>  'NA',
			probefile_ftp =>  'NA',
			submission_date 	=>  'NA',
			probefile_number  =>  0,
		};

		my @lines;		
		my $fCont 	=   q{};
		open	FILE, "$file" or die "No file $file $!";
		local 	$/;															# no input separator
		$fCont   		=	  <FILE>;
		close FILE;
		foreach (split(/\r\n?|\n/, $fCont)) { push @lines, $_ }

		my $gse =   ( @{ pgxdb_geosoft_extract_ids_from_array(\@lines, 'GSE') } )[0];

		if ($gse !~ /^GSE\d+?$/) {
			print "\n";
			print "no GSE?!, $gsm, $gse\n";
			$gse    =   'possibly_private';
		}

		# GSM go into series dir
		my $gseDir  =   $pgxdb->{paths}->{geometadir}.'/'.$gse;
		mkdir $gseDir;
		$pgxdb->{samples}->{meta}->{$gsm}->{GSE} =   $gse;

		# GPL
		my $gpl   =   ( @{ pgxdb_geosoft_extract_ids_from_array(\@lines, 'GPL') } )[0];
		if ($gpl =~ /^GPL\d+?$/) {
			$pgxdb->{samples}->{meta}->{$gsm}->{GPL} = $gpl }

		# date
		my $submissionDate  =   [ grep{ /Sample_submission_date \= \w{3} \d\d? \d{4}/ } @lines ];
		my $date  =   $submissionDate->[0];
		if ($date =~ /\= +?(\w{3}) (\d\d?) (\d{4})/) {
			my ($year, $mon, $day)  =   ($3, $1, $2);
			$mon    =   pgxdb_month_to_number($mon);
			$day    =~  s/^(\d)$/0$1/i;
			$pgxdb->{samples}->{meta}->{$gsm}->{submission_date}  =  join('-', ($year, $mon, $day));
		}

		# probe file
		my @probeFileFTPs 		=   grep{ /Sample_supplementary_file \= ftp.*?\.gz.*?/i } @lines;
#		my $celFileFTP  =   [ grep{ /Sample_supplementary_file \= ftp.*?\.CEL\.gz.*?/i } @lines ];
  	for my $f (0..$#probeFileFTPs) {
  		$probeFileFTPs[$f]	=~  s/^.*?\= ?ftp/ftp/;
  		$probeFileFTPs[$f]	=~  s/((\.tar)?\.gz).*?$/$1/;
  		$probeFileFTPs[$f]	=~  s/\#/\%23/g;
  	}
		$pgxdb->{samples}->{meta}->{$gsm}->{probefile_ftp}  =   join('::', @probeFileFTPs);
		$pgxdb->{samples}->{meta}->{$gsm}->{probefile_number}   =   scalar @probeFileFTPs;

		############################################################################

		if ($gse !~ /^GSE\d+?$|^possibly_private$/) {
			unlink $file;
			print "\ndeleted $file\n";
		} else {
			my $gsmDir  =   $gseDir.'/'.$gsm;
			my $gsmSoft =   $gsmDir.'/geometa.soft';
			mkdir $gsmDir;
			copy($file, $gsmSoft);

			$pgxdb->{samples}->{meta}->{$gsm}->{geosoft_local}  =   $gsmSoft;

		}
  }

  return $pgxdb;

}

################################################################################

sub pgxdb_GEO_GSE_metadata {

=pod

=cut

  my $pgxdb      =   shift;

  $pgxdb->{series}->{meta} =   {};

	my $i					=		0;
	my $gseNo			=		keys %{ $pgxdb->{series} };
	
  for my $gse (sort grep{ /GSE/ } keys %{ $pgxdb->{series} }) {

		$i++;
		
    my $url			=		$pgxdb->{config}->{urls}->{geosoftlink}.$gse;
    my $file		=		$pgxdb->{paths}->{geotmpdir}.'/'.$gse.'.geometa.soft';

    if (
      (! -f $file)
      ||
      $pgxdb->{parameters}->{forcegse} =~ /y/i
    ) {
  		print 'trying '.$gse.' ('.$i.'/'.$gseNo.')'."\n";
  		my $status		=		getstore($url, $file);
  		print "No file file be loaded from\n$url\n" unless is_success($status);
  	}

    $pgxdb->{series}->{meta}->{$gse}	=   {
			GSE     	=>  $gse,
			geosoft_url   =>  $url,
			geosoft_local =>  'NA',
			PMID    	=>  'NA',
			GPL     	=>  'NA',
			bioproject		=>	'NA',
			contact_name 	=>  'NA',
			contact_email =>  'NA',
			city    	=>  'Atlantis',
			submission_date =>  'NA',
			match_words		=>  'n',
		};

    if (! -f $file) {
      print 'no file could be loaded: '.$file."\n";
      next;
    }

		my @lines;		
		my $fCont 	=   q{};
		open	FILE, "$file" or die "No file $file $!";
		local 	$/;															# no input separator
		$fCont   =	  <FILE>;
		close FILE;
		foreach (split(/\r\n?|\n/, $fCont)) { push @lines, $_ }

		my $gseDir  =   $pgxdb->{paths}->{geometadir}.'/'.$gse;
		mkdir $gseDir;

		# contact
		my $contact =   ( grep{ /Series_contact_name ?\= *?\w+/ } @lines )[0];
		$contact    =~  s/^.*Series_contact_name ?\= *?//g;
		$contact    =~  s/[^\w\,\-]//g;
		my ($first,$middle,$last) =   split(',', $contact);
		if ($last  =~ /\w+/) {
			if ($first =~ /\w+/) { $first = $first.' ' }
			if ($middle =~ /\w+/) { $middle = $middle.' ' }
			$pgxdb->{series}->{meta}->{ $gse }->{contact_name} =   $first.$middle.$last;
		}

		# email
		my $email   =   ( grep{ /Series_contact_email ?\= *?\w+/ } @lines )[0];
		$email      =~  s/^.*Series_contact_email ?\= *?//g;
		$email      =~  s/[^\w\.\@\-]//g;
		if ($email  =~ /^[\w\,\.\-]+?\@[\w\,\.\-]+?\.\w{2,6}?$/) {
			$pgxdb->{series}->{meta}->{ $gse }->{contact_email} =   $email }

		# city
		my $city    =   ( grep{ /Series_contact_city ?\= *?\w+/ } @lines )[0];
		$city       =~  s/^.*Series_contact_city ?\= *?//g;
		$city       =~  s/[^\w ]/ /g;
		$city       =~  s/ {2,9}/ /g;
		if ($city  =~ /\w/) {
			$pgxdb->{series}->{meta}->{ $gse }->{city} =   $city }

		# date
		my $submissionDate  =   [ grep{ /Series_submission_date \= \w{3} \d\d? \d{4}/ } @lines ];
		my $date    =   $submissionDate->[0];
		if ($date =~ /\= +?(\w{3}) (\d\d?) (\d{4})/) {
			my ($year, $mon, $day)  =   ($3, $1, $2);
			$mon      =   pgxdb_month_to_number($mon);
			$day      =~  s/^(\d)$/0$1/i;
			$pgxdb->{series}->{meta}->{$gse}->{submission_date}  =  join('-', ($year, $mon, $day));
		}

		# match_words
		my @keywords    =   ();
		for my $keyword (grep{ /\w\w\w/ } @{ $pgxdb->{config}->{cancer_matchwords} }) {
			if (grep { /$keyword/i } @lines) {
				push(@keywords, $keyword);
		}}
		$pgxdb->{series}->{meta}->{ $gse }->{match_words}  =   join('::', @keywords);
		@keywords       =   ();
		for my $keyword (grep{ /\w\w\w/ } @{  $pgxdb->{config}->{cancer_nomatch}  }) {
			if (grep { /$keyword/ } @lines) {
				push(@keywords, $keyword) }
		}
		$pgxdb->{series}->{meta}->{$gse}->{NEGWORDS}  =   join('::', @keywords);
		$pgxdb->{series}->{meta}->{$gse}->{GPL}       =   join(',', @{ pgxdb_geosoft_extract_ids_from_array(\@lines, 'GPL') });

		# PMID
		my $pmid    =   ( grep{ /Series_pubmed_id ?\= ?\d+/ } @lines )[0];
		$pmid       =~  s/[^\d]//g;

		# bioproject
		my @bioprojects = 	grep{ /Series_relation.+?bioproject/i } @lines;
  	for my $bi (0..$#bioprojects) {
  		$bioprojects[$bi] =~  s/^.*?\/(\w+?)$/$1/g;
  	}

		if (grep{ /.../i } @bioprojects) {
			$pgxdb->{series}->{meta}->{ $gse }->{bioproject} 	=   join(',', @bioprojects) }

		my $gseSoft     =   $gseDir.'/geometa.soft';
		copy($file, $gseSoft);

		$pgxdb->{series}->{meta}->{ $gse }->{geosoft_local} =   $gseSoft;

  }

  return $pgxdb;

}








1;
