package PGXDB::GEOrawData;

use Data::Dumper;
use File::Copy;
use LWP::Simple;

require Exporter;
@ISA    =   qw(Exporter);
@EXPORT =   qw(
	pgxdb_download_probefiles
	pgxdb_filter_downloads
	pgxdb_read_GSM_logfile
);

################################################################################
################################################################################
################################################################################

sub pgxdb_filter_downloads {

  my $pgxdb    	=   shift;

	if ($pgxdb->{parameters}->{probefiles} =~ /\w\w/) {
		my @buffer;
		foreach my $download (@{ $pgxdb->{downloads} }) {
			if (grep{ $download->{probefile_ftp} =~ /$_/i } split(',', $pgxdb->{parameters}->{probefiles})) {
				push(@buffer, $download) }
		}
		$pgxdb->{downloads}	=		\@buffer;
	}

	if ($pgxdb->{parameters}->{filters} =~ /\w\w/) {
		$pgxdb->{parameters}->{filters}	=~	s/[^\w\,\.\-\:]//g;	
		foreach my $filter (split(',', $pgxdb->{parameters}->{filters})) {
			$pgxdb->{downloads} = 	[ grep{ $_->{probefile_ftp} =~ /$filter/i } @{ $pgxdb->{downloads} } ];
	}}

	return $pgxdb;
	
}

################################################################################

sub pgxdb_download_probefiles {

	use Archive::Extract;
	use File::Fetch;

  my $pgxdb    	=   shift;

	my $i 					=		0;
	foreach my $gsm_meta (@{ $pgxdb->{downloads} }) {
		$i++;

		my $gseDir  =   $pgxdb->{paths}->{georawdir}.'/'.$gsm_meta->{GSE};
		my $gsmDir  =   $gseDir.'/'.$gsm_meta->{GSM};
		
		mkdir $gseDir;
		mkdir $gsmDir;

		foreach (split('::', $gsm_meta->{probefile_ftp})) {
			
			my $probefileLoc 	=		$_;

			if ($pgxdb->{parameters}->{probefiles} =~ /../) {
				if (! grep{ $probefileLoc =~ /$_/i } split(',', $pgxdb->{parameters}->{probefiles})) {
					next } }
			
			$probefileLoc	=~	s/^.*?\/([^\/]+?$)/$1/;
			$probefileLoc	=~	s/\.gz$//i;		
			$probefileLoc	=		$gsmDir.'/'.$probefileLoc;

			if (-f $probefileLoc) { next }

			print "
$i / ".@{ $pgxdb->{downloads} }.": Fetching	
  $_
  => $probefileLoc\n";

			my $fh        =   File::Fetch->new(uri => $_);
			my $where     =   $fh->fetch(to => $gsmDir ) or die $ff->error;
		# name of the file downloaded
			my $gzDlName   	=   $fh->file;
			my $gzDl				=		$gsmDir.'/'.$gzDlName;
			my $ae          =   Archive::Extract->new( archive => $gzDl );
			my $ok          =   $ae->extract( to => $gsmDir) or warn $ae->error;
			if (-f $probefileLoc) {
				unlink $gzDl or warn "Could not unlink $gzDl" }
				
		}

	}

	return $pgxdb;
	
}

################################################################################

sub pgxdb_read_GSM_logfile {

  my $pgxdb    	=   shift;
  
  $pgxdb->{downloads}	=		[];
	my @lines;
	my $fCont 		=   q{};
	open	FILE, "$pgxdb->{parameters}->{gsmfile}" or die "$pgxdb->{parameters}->{gsmfile} $!";
	local 	$/;															# no input separator
	$fCont  			=	  <FILE>;
	close FILE;
	foreach (split(/\r\n?|\n/, $fCont)) { push @lines, $_ }

	my @header		=		split("\t", shift @lines);
	my %keyPos		=		map{ $header[$_] =>	$_ } 0..$#header;

	foreach my $meta (@lines) {
		my @current	=		split("\t", $meta);
		push(
			@{$pgxdb->{downloads}},
			{ map{ $_ => $current[ $keyPos{ $_ } ] } keys %keyPos },
		);
	}
	return $pgxdb;

}



1;
