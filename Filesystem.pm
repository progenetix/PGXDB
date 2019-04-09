package PGXDB::Filesystem;

require Exporter;
use Data::Dumper;
use File::Path qw(make_path);

@ISA    =   qw(Exporter);
@EXPORT =   qw(
  pgxdb_check_root_dir
  pgxdb_create_paths
  pgxdb_create_log_file_names
);


################################################################################
# utilities ####################################################################
################################################################################

sub pgxdb_check_root_dir {

	my $pgxdb			=		shift;	

	my $error			=		q{};
	if ($pgxdb->{parameters}->{out} !~ /[\w\.]/) {	
		$error			=		'No output location was specified. Please provide an existing directory using the "-out" parameter.' }
	elsif (! -d $pgxdb->{parameters}->{out}) {
		$error			=		'
The specified root directory
  '.$pgxdb->{parameters}->{out}.'
... does not exist. Please create it first, or change the "-out" parameter' }
		
	if ($error =~ /.../) {
	
		print <<END;

############################################################

$error

############################################################

END
		
		exit;
		
	}
	
	$pgxdb->{parameters}->{out}	=~	s/\/$//;
	return $pgxdb;

}

################################################################################

sub pgxdb_create_paths {

	my $pgxdb			=		shift;

	$pgxdb->pgxdb_check_root_dir();

	foreach (keys %{ $pgxdb->{config}->{directories} }) { 
		$pgxdb->{paths}->{$_}	=		$pgxdb->{parameters}->{out}.'/'.$pgxdb->{config}->{directories}->{$_};
		make_path($pgxdb->{paths}->{$_});
	}

	return $pgxdb;
	
}

################################################################################

sub pgxdb_create_log_file_names {

	my $pgxdb			=		shift;
	
	$pgxdb->{logfiles} =   {
		gsmDataFile       =>  $pgxdb->{paths}->{logdir}.'/gsminfo.tab',
		gsmLogFile       	=>  $pgxdb->{paths}->{logdir}.'/gsmlog.tab',
		gseDataFile       =>  $pgxdb->{paths}->{logdir}.'/gseinfo.tab',
		gsmIdFile         =>  $pgxdb->{paths}->{logdir}.'/gsmids.tab',
		pmidAllFile       =>  $pgxdb->{paths}->{logdir}.'/pmid.tab',
		pmidMissingFile   =>  $pgxdb->{paths}->{logdir}.'/pmid_missing.tab',
		pmidMissingCaFile =>  $pgxdb->{paths}->{logdir}.'/pmid_missing_cancer.tab',
	};

	if ( $pgxdb->{parameters}->{randno} > 0 ) {
		foreach (keys %{ $pgxdb->{logfiles} }) {
			$pgxdb->{logfiles}->{ $_ } =~  s/\.tab$/,randno_$pgxdb->{parameters}->{randno}.tab/;
	}}

	if ( $pgxdb->{parameters}->{randpf} > 0 ) {
		foreach (keys %{ $pgxdb->{logfiles} }) {
			$pgxdb->{logfiles}->{ $_ } =~  s/\.tab$/,randpf_$pgxdb->{parameters}->{randpf}.tab/;
	}}

	if ( $pgxdb->{parameters}->{selpf} =~ /GPL/ ) {
		foreach (keys %{ $pgxdb->{logfiles} }) {
			$pgxdb->{logfiles}->{ $_ } =~  s/\.tab$/,selpf_$pgxdb->{parameters}->{selpf}.tab/;
	}}

	if ($pgxdb->{parameters}->{amexclude} =~ /y/i) {
		foreach (keys %{ $pgxdb->{logfiles} }) {
			$pgxdb->{logfiles}->{ $_ } =~  s/\.tab$/,excluding_arraymap.tab/;
	}}
	
	return $pgxdb;
	
}
	

1;
