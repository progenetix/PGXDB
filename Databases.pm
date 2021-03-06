package PGXDB::Databases;

use PGX::Helpers::UtilityLibs;

require Exporter;
@ISA    =   qw(Exporter);
@EXPORT =   qw(
  pgxdb_get_database_platforms
  pgxdb_get_database_samples
  pgxdb_filter_platforms
);


################################################################################

sub pgxdb_get_database_platforms {

	use MongoDB;

	my $pgxdb			=		shift;
	$pgxdb->{platforms}->{existing}	=		[];
	
	if ($pgxdb->{parameters}->{sel_platforms} =~ /.../i) 	{ return $pgxdb }
	if ($pgxdb->{parameters}->{am_platforms} =~ /n/i) 		{ return $pgxdb }

  my $dbconn    =   MongoDB::MongoClient->new()->get_database('arraymap');
  my $distincts =   $dbconn->run_command([
                      "distinct"=>	'biosamples',
                      "key"     =>  'external_references.type.id',
                      "query"   =>  { 'external_references.type.id' => qr/GPL/i },
                    ]);
  my $ids  			=   $distincts->{values};
  $ids					=		[ grep{ /GPL/ } @$ids ];
 	s/^\w+?\://g for @$ids;

	$pgxdb->{platforms}->{existing}	=		$ids;

	return $pgxdb;

}

################################################################################

sub pgxdb_get_database_samples {

	use MongoDB;

	my $pgxdb			=		shift;	
	$pgxdb->{samples}->{existing}		=		[];
	
	if ($pgxdb->{parameters}->{am_samples} =~ /y/i) { return $pgxdb }

  my $dbconn    =   MongoDB::MongoClient->new()->get_database('arraymap');
  my $distincts =   $dbconn->run_command([
                      "distinct"=>	'biosamples',
                      "key"     =>  'external_references.type.id',
                      "query"   =>  { 'external_references.type.id' => qr/GSM/i },
                    ]);
  my $ids  			=   $distincts->{values};
  $ids					=		[ grep{ /GSM/ } @$ids ];
 	s/^\w+?\://g for @$ids;

	$pgxdb->{samples}->{existing}	=		$ids;

	return $pgxdb;

}

################################################################################

sub pgxdb_filter_platforms {

	my $pgxdb			=		shift;
	$pgxdb->{platforms}->{selected}	=		[];

	if ($pgxdb->{parameters}->{sel_platforms} =~ /.../i) {
		$pgxdb->{platforms}->{selected}	=		[ split(',', $pgxdb->{parameters}->{sel_platforms} ) ];
		return $pgxdb;
	}

	foreach my $pfId (@{$pgxdb->{platforms}->{existing}}, @{ $pgxdb->{arrayconfig}->{platforms}->{blessed} }) {
		if (! grep{ /^$pfId$/ } (@{ $pgxdb->{platforms}->{selected} }, @{ $pgxdb->{arrayconfig}->{platforms}->{excluded} }) ) {
			push(@{ $pgxdb->{platforms}->{selected} }, $pfId) }
	}

  if ($pgxdb->{parameters}->{randpf} > 0) {
    $pgxdb->{platforms}->{selected}  =   RandArr( $pgxdb->{platforms}->{selected}, $pgxdb->{parameters}->{randpf} ) }

	return $pgxdb;

}




1;
