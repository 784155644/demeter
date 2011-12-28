package Demeter::UI::HephaestusApp;

=for Copyright
 .
 Copyright (c) 2006-2011 Bruce Ravel (bravel AT bnl DOT gov).
 All rights reserved.
 .
 This file is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself. See The Perl
 Artistic License.
 .
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

use Wx::Perl::Carp;
use File::Spec;

use Demeter qw(:hephaestus);
use Demeter::UI::Hephaestus::Common qw(hversion);

use Wx qw( :everything );
use base 'Wx::Frame';
use Wx::Event qw(EVT_TOOLBOOK_PAGE_CHANGED EVT_TOOLBOOK_PAGE_CHANGING);

$SIG{__WARN__} = sub {Wx::Perl::Carp::warn($_[0])};

my $header_color = Wx::Colour->new(68, 31, 156);

my %note_of = (absorption   => 'periodic table of edge and line energies',
	       formulas     => 'compute total cross sections of materials',
	       data	    => 'periodic table of physical and chemical data',
	       ion	    => 'optimize ion chamber gases',
	       transitions  => 'electronic transitions for fluorescence lines',
	       find	    => 'ordered list of absorption edge energies',
	       line	    => 'ordered list of fluorescence line energies',
	       standards    => 'periodic table of XAS data standards',
	       f1f2	    => 'periodic table of anomalous scattering',
	       help	    => 'Hephaestus User\'s Guide',
	       configure    => 'control details of Hephaestus\' behavior',
	     );
my %label_of = (absorption   => 'Absorption',
		formulas     => 'Formulas',
		data	     => 'Data',
		ion	     => 'Ion chambers',
		transitions  => 'Transitions',
		find	     => 'Edge finder',
		line	     => 'Line finder',
		standards    => 'Standards',
		f1f2	     => "F' and F\"",
		help	     => 'Document',
		configure    => 'Configure',
	       );
my $icon_dimension = 30;

use vars qw($periodic_table);

my @utilities = qw(absorption formulas ion data transitions find line standards f1f2 configure); # help);

sub new {
  my $ref    = shift;
  my $width  = 100;
  my $height = int(($#utilities+1) * $icon_dimension * 1.85); # + 2*($#utilities+1);
  my $self   = $ref->SUPER::new( undef,           # parent window
				 -1,              # ID -1 means any
				 'Hephaestus',    # title
				 wxDefaultPosition, [-1,$height],
			       );
  my $tb = Wx::Toolbook->new( $self, -1, wxDefaultPosition, wxDefaultSize, wxBK_LEFT );
  my $statusbar = $self->CreateStatusBar;
  $self->{book}      = $tb;
  $self->{statusbar} = $statusbar;
  my $vbox = Wx::BoxSizer->new( wxVERTICAL);

  my $imagelist = Wx::ImageList->new( $icon_dimension, $icon_dimension );
  foreach my $utility (@utilities) {
    my $icon = File::Spec->catfile($Demeter::UI::Hephaestus::hephaestus_base, 'Hephaestus', 'icons', "$utility.png");
    $imagelist->Add( Wx::Bitmap->new($icon, wxBITMAP_TYPE_PNG) );
  };
  $tb->AssignImageList( $imagelist );
  foreach my $utility (@utilities) {
    my $count = $tb->GetPageCount;
    #my $select = ($count) ? 0 : 1;
    my $page = Wx::Panel->new($tb, -1);
    my $box = Wx::BoxSizer->new( wxVERTICAL );
    $page -> SetSizer($box);

    ##$periodic_table = Demeter::UI::Wx::PeriodicTable->new($page, sub{$self->multiplex($_[0])}, $statusbar);

    my $label = $label_of{$utility}.': '.$note_of{$utility};
    my $hh = Wx::BoxSizer->new( wxHORIZONTAL );
    my $header = Wx::StaticText->new( $page, -1, $label, wxDefaultPosition, wxDefaultSize );
    $header->SetForegroundColour( $header_color );
    $header->SetFont( Wx::Font->new( 16, wxDEFAULT, wxNORMAL, wxBOLD, 0, "" ) );
    $hh -> Add($header, 0, wxLEFT, 5);
    $box -> Add($hh, 0);

    $self->{$utility}
      = ($utility eq 'absorption')  ? Demeter::UI::Hephaestus::Absorption  -> new($page,$statusbar)
      : ($utility eq 'configure')   ? Demeter::UI::Hephaestus::Config      -> new($page,$statusbar)
      : ($utility eq 'data')        ? Demeter::UI::Hephaestus::Data        -> new($page,$statusbar)
      : ($utility eq 'f1f2')        ? Demeter::UI::Hephaestus::F1F2        -> new($page,$statusbar)
      : ($utility eq 'find')        ? Demeter::UI::Hephaestus::EdgeFinder  -> new($page,$statusbar)
      : ($utility eq 'formulas')    ? Demeter::UI::Hephaestus::Formulas    -> new($page,$statusbar)
      : ($utility eq 'help')        ? Demeter::UI::Hephaestus::Help        -> new($page,$statusbar)
      : ($utility eq 'ion')         ? Demeter::UI::Hephaestus::Ion         -> new($page,$statusbar)
      : ($utility eq 'line')        ? Demeter::UI::Hephaestus::LineFinder  -> new($page,$statusbar)
      : ($utility eq 'standards')   ? Demeter::UI::Hephaestus::Standards   -> new($page,$statusbar)
      : ($utility eq 'transitions') ? Demeter::UI::Hephaestus::Transitions -> new($page,$statusbar)
      :                               0;
    if ($self->{$utility}) {
      $hh   = Wx::BoxSizer->new( wxHORIZONTAL );
      $hh  -> Add($self->{$utility}, 1, wxGROW|wxEXPAND|wxALL, 0);
      $box -> Add($hh, 1, wxEXPAND|wxALL, 0);
      my $this_width = ($self->{$utility}->GetSizeWH)[0];
      my $this_height = ($self->{$utility}->GetSizeWH)[1];
      ($height = $this_height) if ($this_height > $height);
      ($width  = $this_width)  if ($this_width > $width);
      #print $utility, "  ", $this_height, "  ", $height, $/;
    };
    $tb->AddPage($page, $label_of{$utility}, 0, $count);
    $height = ($tb->GetSizeWH)[1];
  };

  $vbox -> Add($tb, 1, wxEXPAND|wxALL, 0);
  EVT_TOOLBOOK_PAGE_CHANGED( $self, $tb, sub{$statusbar->SetStatusText(q{})} );

  ##            largest utility + width of toolbar text + width of icons
  my $framesize = Wx::Size->new(1.05*$width+$icon_dimension+103,
				int($height*($#utilities+1.5)/$#utilities)
			       );
  $self -> SetSize($framesize);


  $self -> SetSizer($vbox);
  #$vbox -> Fit($tb);
  #$vbox -> SetSizeHints($tb);
  return $self;
};

sub do_the_size_dance {
  my ($top) = @_;
  my @size = $top->GetSizeWH;
  $top -> SetSize($size[0], $size[1]+1);
  $top -> SetSize($size[0], $size[1]);
};


package Demeter::UI::Hephaestus;
use File::Basename;

use Wx qw(wxBITMAP_TYPE_XPM wxID_EXIT wxID_ABOUT);
use Wx::Event qw(EVT_MENU EVT_CLOSE);
use base 'Wx::App';

use Demeter qw(:hephaestus);
use Demeter::UI::Hephaestus::Common qw(hversion hcopyright hdescription);

use Readonly;
Readonly my $CONFIG   => Wx::NewId();
Readonly my $DOCUMENT => Wx::NewId();

sub identify_self {
  my @caller = caller;
  return dirname($caller[1]);
};
use vars qw($hephaestus_base $demeter $frame);
$hephaestus_base = identify_self();

sub OnInit {
  $demeter = Demeter->new;
  $demeter -> mo -> ui('Wx');
  $demeter -> mo -> identity('Hephaestus');
  ## read hephaestus' demeter_conf file
  #my $conffile = File::Spec->catfile(dirname($INC{'Demeter/UI/Hephaestus.pm'}), 'Hephaestus', 'data', "hephaestus.demeter_conf");
  #$demeter -> co -> read_config($conffile);
  ## read ini file...
  #$demeter -> co -> read_ini('hephaestus');
  $demeter -> plot_with($demeter->co->default(qw(plot plotwith)));

  foreach my $m (qw(Absorption Formulas Ion Data Transitions EdgeFinder LineFinder
		    Standards F1F2 Config)) { # Help
    next if $INC{"Demeter/UI/Hephaestus/$m.pm"};
    ##print "Demeter/UI/Hephaestus/$m.pm\n";
    require "Demeter/UI/Hephaestus/$m.pm";
  };

  ## -------- create a new frame and set icon
  $frame = Demeter::UI::HephaestusApp->new;
#  $frame -> do_the_size_dance;
  my $iconfile = File::Spec->catfile(dirname($INC{'Demeter/UI/Hephaestus.pm'}), 'Hephaestus', 'icons', "vulcan.xpm");
  my $icon = Wx::Icon->new( $iconfile, wxBITMAP_TYPE_XPM );
  $frame -> SetIcon($icon);

  ## -------- Set up menubar
  my $bar = Wx::MenuBar->new;
  my $file = Wx::Menu->new;
  $file->Append( wxID_EXIT, "E&xit\tCtrl+q" );

  my $help = Wx::Menu->new;
  $help->Append( $CONFIG,    "&Configure" );
  $help->Append( $DOCUMENT,  "&Document" );
  $help->Append( wxID_ABOUT, "&About..." );

  $bar->Append( $file, "&File" );
  $bar->Append( $help, "&Help" );
  $frame->SetMenuBar( $bar );
  EVT_MENU( $frame, $CONFIG,   sub{shift->{book}->SetSelection(9)});
  EVT_MENU( $frame, $DOCUMENT, sub{shift->{book}->SetSelection(10)});
  EVT_MENU( $frame, wxID_ABOUT, \&on_about );
  EVT_MENU( $frame, wxID_EXIT, sub{shift->Close} );
  EVT_CLOSE( $frame,  \&on_close);

  ## -------- fix up frame contents
  $frame->{find}->adjust_column_width;
  $frame->{line}->adjust_column_width;

  $frame -> Show( 1 );
};

sub multiplex {
  print join(" ", @_), $/;
};

sub on_close {
  my ($self) = @_;
  $self->Destroy;
};

sub on_about {
  my ($self) = @_;

  my $info = Wx::AboutDialogInfo->new;

  $info->SetName( 'Hephaestus' );
  $info->SetVersion( hversion() );
  $info->SetDescription( hdescription() );
  $info->SetCopyright( hcopyright() );
  $info->SetWebSite( 'http://cars9.uchicago.edu/iffwiki/Demeter', 'The Demeter web site' );
  $info->SetDevelopers( ["Bruce Ravel <bravel\@bnl.gov>\n",
			 "See the document for literature references\nfor the data resources.\n",
			 "Much of the data displayed in the Data\nutility was swiped from Kalzium (website...)\n",
			 "Mossbauer data comes from http://mossbauer.org/",
			] );
  $info->SetLicense( $demeter->slurp(File::Spec->catfile($Demeter::UI::Hephaestus::hephaestus_base, 'Hephaestus', 'data', "GPL.dem")) );
  my $artwork = <<'EOH'
The logo and main icon is "Vulcan Forging 
Jupiter's Lightning Bolts" by Peter Paul
Rubens, from Wikimedia http://commons.wikimedia.org/

The edge finder and configure icons are from
the Kids icon set for KDE by Everaldo Coelho,
http://www.everaldo.com

The Absorption (gold), Formulas (mortar), Data
(chemical hazard), Document (book) icons taken
from Wikimedia http://commons.wikimedia.org
(search terms)

The F1F2 icon is adapted from graphics at Matt's
diffkk homepage http://cars9.uchicago.edu/dafs/diffkk/

The ion chamber icon is taken from the ADC website
http://www.adc9001.com/index.php?src=synchrotron

I don't recall the provenance of the transitions
icon.

The line finder icon is from Fig 2, Ni panel at
http://alpha.asi.ualberta.com/ProjectAreas/XraySpec/xrayproj.htm

The standards icon is a photo of the EXAFS Materials
box of foils swiped from the APS XSD website.
http://www.aps.anl.gov/Xray_Science_Division/Beamline_Technical_Support/Equipment_Pool/Equipment_Information/3d_Metal_Foil_Set/
EOH
  ;
  $info -> AddArtist($artwork);

  Wx::AboutBox( $info );
}

1;

=head1 NAME

Demeter::UI::Hephaestus - A souped-up periodic table for XAS

=head1 VERSION

This documentation refers to Demeter version 0.5.

=head1 SYNOPSIS

  use Demeter::UI::Hephaestus;
  my $window = Demeter::UI::Hephaestus->new;
  $window -> MainLoop;

=head1 DESCRIPTION

Hephaestus is a graphical interface to tables of X-ray absorption
coefficients and elemental data.  The utilities contained in
Hephaestus serve a wide variety of useful functions as you prepare for
and perform an XAS experiment.

=head1 CONFIGURATION


=head1 DEPENDENCIES

Demeter's dependencies are in the F<Bundle/DemeterBundle.pm> file.

=head1 BUGS AND LIMITATIONS

=over 4

=item *

Use a StatusBar.

=item *

Add and delete user materials for Formula utility using an ini file.

=item *

Configuration callback currently does nothing with units

=item *

Calculations not sensitive to units settings

=item *

There is a display problem with the pressure slider in the Ion utility

=item *

Consider SRS amplifiers in Ion utility

=back

Please report problems to Bruce Ravel (bravel AT bnl DOT gov)

Patches are welcome.

=head1 AUTHOR

Bruce Ravel (bravel AT bnl DOT gov)

L<http://cars9.uchicago.edu/~ravel/software/>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2011 Bruce Ravel (bravel AT bnl DOT gov). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlgpl>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut