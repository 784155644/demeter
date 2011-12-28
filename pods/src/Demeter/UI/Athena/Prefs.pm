package Demeter::UI::Athena::Prefs;

use strict;
use warnings;

use Demeter::UI::Wx::Config;

use Wx qw( :everything );
use base 'Wx::Panel';
use Wx::Event qw(EVT_BUTTON);

use List::MoreUtils qw(none);

use vars qw($label $tag);
$label = "Preferences";
$tag = 'Prefs';

sub new {
  my ($class, $parent, $app) = @_;
  my $this = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxMAXIMIZE_BOX );

  my $box = Wx::BoxSizer->new( wxVERTICAL);
  $this->{sizer}  = $box;
  $this->{parent} = $parent;

  my $config = Demeter::UI::Wx::Config->new($this, \&target);
  $config->populate([qw(athena bft bkg clamp convolution fft file fit gnuplot indicator
			interpolation lcf marker merge operations pca peakfit plot rebin xanes)]);
  $box->Add($config, 1, wxGROW|wxALL, 5);
  $config->{params}->Expand($config->{params}->GetRootItem);

  $this->{document} = Wx::Button->new($this, -1, 'Document section: preferences');
  $box -> Add($this->{document}, 0, wxGROW|wxALL, 2);
  EVT_BUTTON($this, $this->{document}, sub{  $app->document("preferences")});

  $this->SetSizerAndFit($box);
  return $this;
};

sub target {
  my ($self, $parent, $param, $value, $save) = @_;

 SWITCH: {
    ($parent eq 'lcf') and do {
      last SWITCH if none {$param eq $_} qw(components difference unity inclusive);
      my $p = (($param eq 'components') or ($param eq 'difference')) ? "plot_".$param : $param;
      $::app->{main}->{LCF}->{LCF}->$p($value);
      $::app->{main}->{LCF}->{$param}->SetValue($value);
      last SWITCH;
    };
    ($param eq 'plotwith') and do {
      $Demeter::UI::Athena::demeter->plot_with($value);
      last SWITCH;
    };
    ($param eq 'rmax_out') and do {
      foreach my $i (0 .. $::app->{main}->{list}->GetCount-1) {
	my $this = $::app->{main}->{list}->GetIndexedData($i);
	$this->rmax_out($value);
      };
      last SWITCH;
    };
  };

  ($save)
    ? $::app->{main}->status("Now using $value for $parent-->$param and an ini file was saved")
      : $::app->{main}->status("Now using $value for $parent-->$param");

};

sub pull_values {
  my ($this, $data) = @_;
  1;
};
sub push_values {
  my ($this, $data) = @_;
  1;
};
sub mode {
  my ($this, $data, $enabled, $frozen) = @_;
  1;
};

1;