package PGXDB;

use Data::Dumper;
use File::Basename;
use YAML::XS 'LoadFile';

use PGXDB::Databases;
use PGXDB::Filesystem;
use PGXDB::GEOmetaData;
use PGXDB::GEOrawData;
use PGXDB::Utilities;

require Exporter;
@ISA    =   qw(Exporter);
@EXPORT =   qw(
  new
  pgxdb_month_to_number
);

################################################################################
################################################################################
################################################################################

sub new {

  my $class     =   shift;
  my $args      =   shift;

  my $path_of_this_module = File::Basename::dirname( eval { ( caller() )[1] } );

  my $self      =   {
  	config			=>	LoadFile($path_of_this_module.'/rsrc/config/config.yaml'),
  	platformconfig  =>	LoadFile($path_of_this_module.'/rsrc/config/platforms.yaml'),
  	logfiles		=>	{},
    parameters  =>  {},
    platforms		=>	{},
    samples			=>	{},
    series			=>	{},
  };
  bless $self, $class;
  
	$self->{parameters}	=		{ map{ $_ => $self->{config}->{parameters}->{$_} } keys %{ $self->{config}->{parameters} } };
	$self->{dataset_names}	=		[ keys %{ $self->{config}->{databases} } ];

  if (! grep{ /\-./ }  keys %$args) {
  	$self->{parameters}->{help}	=		1;
  	return $self;
  }

  foreach (grep{ /^\-\w/ } keys %$args) {
    my $key		  =		$_;
    $key				=~	s/^\-//;
    if ($args->{$_}	=~ /./) {
    	$self->{parameters}->{$key}	=		$args->{$_} }
    if (grep{ /^$key$/ } qw(help h ?)) {
    	$self->{parameters}->{help}	=		1 }
  }
  
  return $self;

}


1;
