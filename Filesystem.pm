package PGXDB::Filesystem;

require Exporter;
use Data::Dumper;
use File::Path qw(make_path);
use Term::ProgressBar;

@ISA    =   qw(Exporter);
@EXPORT =   qw(
  pgxdb_check_files_dirs
  pgxdb_create_paths
  pgxdb_create_log_file_names
);


################################################################################
# utilities ####################################################################
################################################################################

sub pgxdb_check_files_dirs {

	my $pgxdb			=		shift;
	my $filekey		=		shift;
	
	if ($filekey !~ /^[\w\-\.]+?$/) { return $pgxdb }

	my $term_bar		=		"\n".("=" x Term::ProgressBar->new({count => 1, silent => 1})->{term_width})."\n";

	if (
		(! -e $pgxdb->{parameters}->{$filekey})
		||
		$pgxdb->{parameters}->{$filekey}	!~ /./
	) {
		print $term_bar.$pgxdb->{config}->{fileerrors}->{$filekey}->{message}.$term_bar;
		exit;
	}
	
	$pgxdb->{parameters}->{out}	=~	s/\/$//;
	return $pgxdb;

}


################################################################################

sub pgxdb_create_paths {

	my $pgxdb			=		shift;

	$pgxdb->pgxdb_check_files_dirs('out');

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

	if ( $pgxdb->{parameters}->{sel_platforms} =~ /GPL/ ) {
		foreach (keys %{ $pgxdb->{logfiles} }) {
			$pgxdb->{logfiles}->{ $_ } =~  s/\.tab$/,selpf_$pgxdb->{parameters}->{sel_platforms}.tab/;
	}}

	if ($pgxdb->{parameters}->{am_samples} =~ /n/i) {
		foreach (keys %{ $pgxdb->{logfiles} }) {
			$pgxdb->{logfiles}->{ $_ } =~  s/\.tab$/,excluding_arraymap.tab/;
	}}
	
	return $pgxdb;
	
}
	

1;
