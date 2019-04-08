package PGXDB::Utilities;

require Exporter;
@ISA    =   qw(Exporter);
@EXPORT =   qw(
  pgxdb_month_to_number
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



1;
