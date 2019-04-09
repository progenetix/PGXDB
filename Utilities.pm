package PGXDB::Utilities;

use Term::ProgressBar;

require Exporter;
@ISA    =   qw(Exporter);
@EXPORT =   qw(
  pgxdb_month_to_number
  print_help
);


################################################################################
# utilities ####################################################################
################################################################################

sub pgxdb_month_to_number {

  my $month     =   shift;
  $month        =~  s/^(\w\w\w).*?$/$1/;
  $month				=		lc($month);
  my %months    =   (
    jan	        =>	'01',
    feb	        =>	'02',
    mar	        =>	'03',
    apr	        =>	'04',
    may	        =>	'05',
    jun	        =>	'06',
    jul	        =>	'07',
    aug	        =>	'08',
    sep	        =>	'09',
    oct	        =>	'10',
    nov	        =>	'11',
    dec	        =>	'12',
  );
  if (grep { /$month/ } keys %months) { $month = $months{$month} }

  return $month;

}


sub print_help {

	my $pgxdb			=		shift;
	
	if (! $pgxdb->{parameters}->{help}) { return $pgxdb }

	my $term_bar		=		"\n".("=" x Term::ProgressBar->new({count => 1, silent => 1})->{term_width})."\n";
	print $term_bar."\n";
	foreach (sort keys %{ $pgxdb->{parameters} }) {
		print "-$_ $pgxdb->{parameters}->{$_}\n";
	}
	print $term_bar;

	exit;

}

1;
