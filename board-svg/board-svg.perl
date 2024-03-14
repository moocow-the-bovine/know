#!/usr/bin/perl -w

use Getopt::Long qw(:config no_ignore_case);
use XML::LibXML;
use strict;

##======================================================================
## command-line
my ($help);
my $outfile = '-';
my $radius = 512;
my $pad = 0;
my $cssfile = '';
my $want_lines = 0;
my $want_points = 0;
my $want_labels = 0;
my $want_rim = 1;
my $want_spaces = 1;
my $want_quadrant = 0;
my $want_template = 0;
my $want_rotate_labels = 0;
my @argv = @ARGV;
GetOptions(
	   'h|help' => \$help,
	   'l|labels!' => \$want_labels,
	   'rotate-labels!' => \$want_rotate_labels,
	   'p|points!' => \$want_points,
	   'L|lines!' => \$want_lines,
	   'R|rim!' => \$want_rim,
	   's|spaces!' => \$want_spaces,
	   'q|quadrant!' => \$want_quadrant,
	   'd|debug!' => sub { $want_lines=$want_points=$want_labels=$_[1] },
	   't|template' => sub { $want_template=$want_spaces=$want_labels=1; $want_lines=$want_points=$want_rim=0; },
	   'r|radius=i' => \$radius,
	   'pad=s' => \$pad,
	   'c|css=s' => \$cssfile,
	   'o|out|outfile=s' => \$outfile,
	  );

if ($help) {
  print STDERR <<EOF;

Usage: $0 \[OPTIONS\]

Options:
  -h, -help                  # this help message
  -l, -[no]labels            # include space labels? (default=no)
    , -[no]rotate-labels     # do/don't rotate labels to center=down (default=no)
  -p, -[no]points            # include points? (default=no)
  -L, -[no]lines             # include lines? (default=no)
  -R, -[no]rim               # include rim lines? (default=yes)
  -s, -[no]spaces            # include spaces? (default=yes)
  -d, -[no]debug             # alias for -[no]lines -[no]points -[no]annotations
  -q, -[no]quadrant          # draw only 1 quadrant? (default=no)
  -t, -[no]template          # template preset (default=no)
  -c, -css CSSFILE           # import cssfile
  -P, -pad PIXELS            # set output padding
  -r, -radius PIXELS         # set output radius
  -o, -out OUT               # output SVG

EOF
  exit 0;
}

##======================================================================
## globals

our $pi = 3.14195;

our $ns = "http://www.w3.org/2000/svg";
our $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
our $root = $doc->createElementNS($ns, 'svg');
$pad += .16*$radius if ($want_points && $want_labels);
$root->setAttribute('version', '1.1');
$root->setAttribute('id', 'board');
$root->setAttribute('viewBox', ($want_quadrant
				? join(' ', -$pad, -($radius+$pad), ($radius+2*$pad), ($radius+2*$pad))
				: join(' ', -($radius+$pad), -($radius+$pad), 2*($radius+$pad), 2*($radius+$pad))));
$root->setAttribute('class', join(' ', 'board',
				  map {'board-'.$_}
				  ($want_lines ? '' : 'no').'lines',
				  ($want_points ? '' : 'no').'points',
				  ($want_labels ? '' : 'no').'labels',
				  ($want_spaces ? '' : 'no').'spaces',
				  ($want_rim ? '' : 'no').'rim',
				  ($want_quadrant ? '' : 'no').'quadrant',
				  ($want_template ? '' : 'no').'template',
				 ));
$doc->setDocumentElement($root);
$doc->insertBefore(XML::LibXML::Comment->new(
"====================================================================
 | File: $outfile
 | Description: know board SVG, auto-generated by $0
 | Command-Line: $0 ".join(' ', @argv)."
 | Options:
 |   radius = $radius
 |   pad = $pad
 |   cssfile = $cssfile
 |   want_lines = $want_lines
 |   want_points = $want_points
 |   want_labels = $want_labels
 |   want_rim = $want_rim
 |   want_spaces = $want_spaces
 |   want_quadrant = $want_quadrant
 ===================================================================="),
		   $root);

our $defs = elt('defs');
$root->addChild($defs);


##======================================================================
## UTILS

sub rad2deg { return $_[0] * 180.0 / $pi; }
sub deg2rad { return $_[0] * $pi / 180.0; }

## %attrs = attrClass($classes, %attrs)
sub attrClass {
  my ($classes, %attrs) = @_;
  my %classes = map {$_=>undef} split(' ', ($classes//'').' '.($attrs{class}//''));
  $attrs{class} = join(' ', sort keys %classes) if (%classes);
  return %attrs;
}

## $nod = addClass($nod, $classes)
sub addClass {
  my ($nod, $classes) = @_;
  $nod->setAttribute('class', attrClass($classes, class=>$nod->getAttribute('class')));
  return $nod;
}

## $nod = setAttrs($nod, $classes, %attrs)
sub setAttrs {
  my $nod = shift;
  my %attrs = attrClass(@_);
  foreach my $key (sort keys %attrs) {
    $nod->setAttribute($key, $attrs{$key});
  }
  return $nod;
}

## $elt = elt($name, $classes, %attrs)
sub elt {
  my $name = shift;
  return setAttrs($doc->createElement($name), @_);
}

## $nod = style($cssbuf, $classes, %attrs)
sub style {
  my ($buf, $classes, %attrs) = @_;
  my $nod = elt('style', $classes, type=>'text/css', %attrs);
  $nod->appendText($buf);
  return $nod;
}

## $nod = group($classes, %attrs)
sub group {
  return elt('g', @_);
}

## $nod = point($x, $y, $classes, %attrs)
our %points = qw();
sub point {
  my ($x, $y, $classes, %attrs) = @_;
  my $nod = elt('circle', (($classes//'').' point'), cx=>$x, cy=>$y, r=>1, %attrs);
  foreach my $c (split(' ', $classes)) {
    $points{$c} = $nod;
  }
  return $nod;
}

## $nod = label($text, $x, $y, $classes, %attrs)
sub label {
  my ($text, $x, $y, $classes, %attrs) = @_;
  my $nod = elt('text', (($classes//'').' label'), x=>$x, y=>$y, 'dominant-baseline'=>'middle', 'text-anchor'=>'middle', %attrs);
  $nod->appendText($text);
  return $nod;
}


## ($x,$y) = vectorCoords($cx, $cy, $angle, $radius)
sub vectorCoords {
  my ($cx, $cy, $angle, $r) = @_;
  return ($cx + $r*cos($angle), $cy + $r*sin($angle))
}

## $nod = line($x1, $y1, $x2, $y2, $classes, %attrs)
our %lines = qw();
sub line {
  my ($x1, $y1, $x2, $y2, $classes, %attrs) = @_;
  my $nod = elt('line', (($classes//'').' line'), x1=>$x1, y1=>$y1, x2=>$x2, y2=>$y2, %attrs); #stroke=>'#000000'
  foreach my $c (split(' ', $classes)) {
    $lines{$c} = $nod;
  }
  return $nod;
}
sub setline {
  my ($linekey, $x1,$y1,$x2,$y2) = @_;
  my $nod = $lines{$linekey} or die("line '$linekey' not found");
  setAttrs($nod, undef, x1=>$x1, y1=>$y1, x2=>$x2, y2=>$y2);
}

## $x = px($i); ...
sub pi { return $_[0] % 16 if ($_[0] =~ /^-?[0-9]+$/); return $_[0]; }
sub px { return ($points{"p".pi($_[0])} || $points{$_[0]})->getAttribute('cx'); }
sub py { return ($points{"p".pi($_[0])} || $points{$_[0]})->getAttribute('cy'); }
sub pxy { return (px(@_), py(@_)); }


## ($x1,$y1,$x2,$y2) = lcoords($line_key)
sub lcoords {
  my $lkey = shift;
  my $nod = $lines{$lkey};
  return ($nod->getAttribute('x1'),
	  $nod->getAttribute('y1'),
	  $nod->getAttribute('x2'),
	  $nod->getAttribute('y2'));
}
sub lineid {
  my $lkey = shift;
  return $lines{$lkey}->getAttribute('id');
}

## ($x, $y) = intersection($lclass1, $lclass2)
## see https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
sub intersection {
  my ($x1,$y1, $x2,$y2) = lcoords($_[0]);
  my ($x3,$y3, $x4,$y4) = lcoords($_[1]);
  my $t = eval {
	   (($x1-$x3)*($y3-$y4) - ($y1-$y3)*($x3-$x4))
	   /
	   (($x1-$x2)*($y3-$y4) - ($y1-$y2)*($x3-$x4))
	 };
  if ($@) {
    die("no intersection for segments \"$_[0]\" and \"$_[1]\"");
  }
  return ($x1 + $t*($x2-$x1), $y1 + $t*($y2-$y1));
}

## $nod = space([$x1,$y1, ... $xN,$yN], $classes, %attrs)
our %spaces = qw();
sub space {
  my ($points, $classes, %attrs) = @_;
  my $nod = elt('polygon', (($classes//'').' space'), points=>join(' ', @$points), %attrs);
  foreach my $c (split(' ', $classes)) {
    $spaces{$c} = $nod;
  }
  return $nod;
}

## ($x1,$y1, ..., $xN,$yN) = vertices($spaceKey)
sub vertices {
  my $skey = shift;
  my $nod = $spaces{$skey} || die("bad space-key '$skey'");
  my $points = $nod->getAttribute('points');
  return split(' ', $points);
}

sub mean {
  my $v = 0;
  $v += $_ foreach (@_);
  return $v / scalar(@_);
}
sub sgn {
  return $_[0] < 0 ? -1 : 1;
}

# see https://rdrr.io/github/jmw86069/jambio/man/jamGeomean.html
#  - no joy
sub gmean {
  my @x = shift;
  my @j = map {sgn($_)+log(1+abs($_))} @x;
  my $k = mean(@j);
  my $m = exp(abs($k));
  my $n = sgn($k)*$m;
  return $n - 1;
}

## ($x, $y) = center_avg($spaceKey)
##  + arithmetic average
sub center_avg {
  my $skey = shift;
  my @vertices = vertices($skey);
  my @xvals = map {$vertices[$_*2]} (0..($#vertices/2));
  my @yvals = map {$vertices[$_*2+1]} (0..($#vertices/2));
  return (mean(@xvals), mean(@yvals));
}


## ($x, $y) = center_geo($spaceKey)
##  + pseudo-geometric average
##  + see https://rdrr.io/github/jmw86069/jambio/man/jamGeomean.html
sub center_geo {
  my $skey = shift;
  my @vertices = vertices($skey);
  my @xvals = map {$vertices[$_*2]} (0..($#vertices/2));
  my @yvals = map {$vertices[$_*2+1]} (0..($#vertices/2));
  return (gmean(@xvals), gmean(@yvals));
}
*center = \&center_avg;
#*center = \&center_geo;

## "Q$i Q$j ... Q$N" = Q($pi1, $pi2, ...)
sub Q {
  my %Q = map {('Q'.int(pi($_)/4))=>undef} @_;
  return join(' ', sort keys %Q);
}

##======================================================================
## MAIN

##--------------------------------------------------------------
## rim (placeholder)
my $rim = $root->addChild(elt('polygon', 'rim Q99', id=>'rim'));
my @rim = qw();

##--------------------------------------------------------------
## points

my $points = $root->addChild(group('points', id=>'points'));
$points->addChild(point(0, 0, 'center', id=>'center'));

my $plabels = $root->addChild(group('labels', id=>'labels'));

##-- rim points & labels
my $angleOffset = -$pi/2 - ($want_quadrant ? 0: $pi/16);
our %pointAngles = qw();
foreach my $i (0..15) {
  $pointAngles{"p$i"} = $i * $pi/8 + $angleOffset;
  $points->addChild(point(vectorCoords(0, 0, $pointAngles{"p$i"}, $radius), "p$i ".Q($i, $i-1), id=>"p$i"));

  my ($lx,$ly) = vectorCoords(0, 0, $pointAngles{"p$i"}, $radius*1.1);
  my $label = label("p$i", $lx, $ly, "p$i ".Q($i, $i-1), id=>"label-p$i");
  if ($want_rotate_labels) {
    $label->setAttribute('transform' => "rotate(".rad2deg($pointAngles{"p$i"}+$pi/2).",$lx,$ly)");
  }
  $plabels->addChild($label);
}
our %wedgeAngles = map {("w$_" => $pointAngles{"p$_"} + $pi/16)} (0..15);


##-- imaginary points
foreach my $q (0..3) {
  my $i = pi($q*4);
  my ($x1,$y1) = pxy($i);
  my ($x2,$y2) = pxy($i-1);
  $points->addChild(point(($x1+$x2)/2, ($y1+$y2)/2, "p${i}i imaginary ".Q($i-1), id=>"p${i}i"));

  $i = pi($q*4+1);
  ($x1,$y1) = pxy($i);
  ($x2,$y2) = pxy($i+1);
  $points->addChild(point(($x1+$x2)/2, ($y1+$y2)/2, "p${i}i imaginary ".Q($i), id=>"p${i}i"));
}


##--------------------------------------------------------------
## lines

##-- radii
## r{i}: 1 ≤ i < 8
my $lines = $root->addChild(group('lines', id=>'lines'));
foreach my $i (0..15) {
  $lines->addChild(line(pxy($i), pxy('center'), "radius r$i ".Q($i), id=>"r$i"));
}

##-- chords (by quadrant)
foreach my $q (0..3) {
  my ($i, $j);

  # long chords (+7), n=4; id="chord-long-$q"
  #  + s{i}> : p{i} -- p{i+7} , i ∈ {1,5,9,13} : i = 4Q+1 (clockwise shortest rim arc)
  #  + s{i}< : p{i} -- p{i-7} , i ∈ {0,4,8,12} : i = 4Q   (widdershins shortest rim arc)
  # - conflict with imaginary segments!
  $i = pi(4*$q+1);
  $j = pi($i+7);
  $lines->addChild(line(pxy($i), pxy($j), "chord long s$i> s$j< ".Q($i,$j-1), id=>"chord-long-$q"));

  # medium chords (+5), n=4; id="chord-medium-$q"
  #  + s{i}> : p{i} -- p{i+5} , i ∈ {2,6,10,14} : i = 4Q+2 (clockwise)
  #  + s{i}< : p{i} -- p{i-5} , i ∈ {7,11,15,3} : i = 4Q+3 (widdershins)
  $i = pi(4*$q+2);
  $j = pi($i+5);
  $lines->addChild(line(pxy($i), pxy($j), "chord medium s$i> s$j< ".Q($i,$j), id=>"chord-medium-$q"));

  # short chords (+3), n=4; id="chord-short-$q"
  $i = pi(4*$q+3);
  $j = pi($i+3);
  $lines->addChild(line(pxy($i), pxy($j), "chord short s$i> s$j< ".Q($i,$j), id=>"chord-short-$q"));
}

##-- arcs (rim segments)
# + z{i}> : p{i} -- p{i+1}
# + z{i}< : p{i} -- p{i-1}
foreach my $i (0..15) {
  my $j = pi($i + 1);
  my @points = (pxy($i), pxy($j));
  $lines->addChild(line(@points, "arc z$i> z$j< ".Q($i,$j), id=>"arc-$i"));
  push(@rim, @points);
}
$rim->setAttribute('points', join(' ', @rim));


##-- imaginary segments
## + s{i}i, i odd
## #+ z{i}i>: p{i}i -- p{i+1}
## #+ z{i}i<: p{i} -- p{i-1}i
foreach my $q (0..3) {
  my $i = pi(4*$q);
  $lines->addChild(line(pxy("${i}i"), intersection("s$i<", 's'.pi($i-1).'>'), "imaginary s${i}i ".Q($i-1), id=>"s${i}i"));

  my $j = pi(4*$q+1);
  $lines->addChild(line(pxy("${j}i"), intersection("s$j>", 's'.pi($j+1).'<'), "imaginary s${j}i ".Q($j), id=>"s${j}i"));

  ##-- shorten long chords to imaginary-intersections
  setline("s$i<", intersection("s$i<", 's'.pi($i-1).'>'), intersection("s$i<", 's'.pi($i-6).'<'));
  setline("s$j>", intersection("s$j>", 's'.pi($j+1).'<'), intersection("s$j>", 's'.pi($j+6).'>'));
}

##--------------------------------------------------------------
## spaces

my $spaces = $root->addChild(group('spaces', id=>'spaces'));
my $sblack = $spaces->addChild(group('black', id=>'black'));
my $swhite = $spaces->addChild(group('white', id=>'white'));
my $slabels = $root->addChild(group('space-labels', id=>'space-labels'));
sub xaddSpace { ; }
sub addSpace {
  my ($color, $id, @borders) = @_;
  my ($wedge, $tier, $suffix);
  if ($id =~ /^a(\d+)\.(\d+)(\S*)$/) {
    ($wedge, $tier, $suffix) = ($1, $2, $3);
  } else {
    die("couldn't parse space-ID '$id'");
  }

  ##-- check lines
  foreach (@borders) {
    die("unknown border '$_' for space '$id'") if (!defined($lines{$_}));
  }

  ##-- compute classes
  my @classes = ($id, $color, "wedge-$wedge", "tier-$tier", Q($wedge),
		 map {"border-".lineid($_)} @borders);

  ##-- compute polygon points from border intersections
  my @vertices = qw();
  my $prev = $borders[0];
  foreach my $border (@borders[1..$#borders]) {
    push(@vertices, intersection($prev, $border));
    $prev = $border;
  }
  push(@vertices, intersection($prev, $borders[0]));

  ##-- create space
  my $group = $color eq 'black' ? $sblack : $swhite;
  $group->addChild(space(\@vertices, join(' ',@classes), id=>$id));

  ##-- create space label
  my ($lx, $ly) = center($id);
  my $label = label("${wedge}.${tier}${suffix}", center($id), "label-$id space-label $color wedge-$wedge tier-$tier ".Q($wedge), id=>"label-$id");
  if ($want_rotate_labels) {
    $label->setAttribute('transform' => "rotate(".rad2deg($wedgeAngles{"w$wedge"}+$pi/2).",$lx,$ly)");
  }
  $slabels->addChild($label);
}

foreach my $q (0..3) {
  ##-------- spaces: wedge-0
  my $w0 = pi($q*4+0);
  my $w = $w0;
  addSpace('black', "a$w.0", ('z'.$w0.'>', 'r'.($w0+1), 's'.($w0+2).'<', 'r'.$w0));
  addSpace('white', "a$w.1", ('r'.pi($w0+1), 's'.pi($w0+2).'<', 'r'.pi($w0), 's'.pi($w0+3).'<'));
  addSpace('black', "a$w.2", ('r'.pi($w0), 's'.pi($w0+3).'<', 'r'.pi($w0+1), 's'.pi($w0+4).'<'));
  addSpace('white', "a$w.3", ('r'.pi($w0+1), 's'.pi($w0+4).'<', 'r'.pi($w)));

  ##-------- spaces: wedge-1
  $w = pi($w0 + 1);
  addSpace('white', "a$w.0a", ("z${w}>", "s${w}i", "s".pi($w0+2)."<", "r$w"));
  addSpace('black', "a$w.0b", ("z$w>", "s${w}i", "s".pi($w0+2)."<"));
  addSpace('black', "a$w.1a", ('s'.pi($w).'>', "s".pi($w0+2)."<", "r".pi($w), "s".pi($w0+3)."<"));
  addSpace('white', "a$w.1b", ('s'.pi($w).'>', "s".pi($w0+2)."<", "r".pi($w0+2), "s".pi($w0+3)."<"));
  addSpace('white', "a$w.2a", ('s'.pi($w).'>', "s".pi($w0+3)."<", "r".pi($w), "s".pi($w0+4)."<", "r".pi($w0+2)));
  addSpace('black', "a$w.2b", ('s'.pi($w).'>', "s".pi($w0+3)."<", "r".pi($w0+2)));
  addSpace('black', "a$w.3", ("r".pi($w0+2), "s".pi($w0+4)."<", "r".pi($w)));

  ##-------- spaces: wedge-2
  $w = pi($w0+2);
  addSpace('white', "a$w.0", ("z$w>", 's'.pi($w0+2).'>', 's'.pi($w0+3).'<'));
  addSpace('black', "a$w.1a", ('s'.pi($w0+2).'>', 's'.pi($w0+3).'<', 'r'.pi($w0+2)));
  addSpace('black', "a$w.1b", ('s'.pi($w0+2).'>', 's'.pi($w0+3).'<', 'r'.pi($w0+3)));
  addSpace('white', "a$w.2a", ('s'.pi($w0+2).'>', 's'.pi($w0+3).'<', 'r'.pi($w0+2), 's'.pi($w0+1).'>', 's'.pi($w0+4).'<', 'r'.pi($w0+3)));
  addSpace('black', "a$w.2b", ('r'.pi($w0+2), 's'.pi($w0+1).'>', 's'.pi($w0+4).'<'));
  addSpace('black', "a$w.2c", ('s'.pi($w0+4).'<', 's'.pi($w0+1).'>', 'r'.pi($w0+3)));
  addSpace('white', "a$w.3", ('s'.pi($w0+4).'<', 'r'.pi($w0+2), 'r'.pi($w0+3), 's'.pi($w0+1).'>'));

  ##-------- spaces: wedge-3 (~ wedge-1 inverted)
  $w = pi($w0 + 3);
  addSpace('black', "a$w.0a", ("z$w>", "s".pi($w0+4)."i", "s".pi($w0+3).">"));
  addSpace('white', "a$w.0b", ("z$w>", "r".pi($w0+4), "s".pi($w).">", "s".pi($w+1)."i"));
  addSpace('white', "a$w.1a", ("s".pi($w0+3).">", "s".pi($w0+4)."<", "s".pi($w0+2).">"), "r".pi($w0+3));
  addSpace('black', "a$w.1b", ("s".pi($w0+4)."<", "s".pi($w0+3).">", "r".pi($w0+4), "s".pi($w0+2).'>'));
  addSpace('black', "a$w.2a", ("s".pi($w0+2).">", "r".pi($w0+3), "s".pi($w0+4)."<"));
  addSpace('white', "a$w.2b", ("s".pi($w0+2).">", "r".pi($w0+4), "s".pi($w0+1).">", "r".pi($w0+3), "s".pi($w0+4)."<"));
  addSpace('black', "a$w.3", ("r".pi($w0+3), "s".pi($w0+1).">", "r".pi($w0+4)));
}

##--------------------------------------------------------------
## quadrant mask-like polygons

my $quadrants = $root->addChild(group('quadrants', id=>'quadrants'));
foreach my $q (0..3) {
  my @points = (pxy('center'), map {pxy($_)} (0..($q*4+4)));
  $quadrants->addChild(elt('polygon', "quadrant Q$q", id=>"Q$q", points=>join(' ', @points)));
}


##--------------------------------------------------------------
## remove debugging objects?

if (!$want_labels) {
  $root->removeChild($slabels);
}
if (!$want_points) {
  $root->removeChild($points);
  $root->removeChild($plabels);
}
if (!$want_lines || $want_quadrant) {
  $root->removeChild($lines);
}
if (!$want_rim || $want_quadrant) {
  $root->removeChild($rim);
}
if (!$want_spaces) {
  $root->removeChild($spaces);
}

if ($want_quadrant) {
  my $nodes = $root->findnodes('.//*[@class]');
  foreach my $nod (@$nodes) {
    my $cls = $nod->getAttribute('class');
    if ($cls =~ /\bQ[0-3]\b/ && $cls !~ /\bQ0\b/) {
      $nod->parentNode->removeChild($nod);
    }
  }
} else {
  $root->removeChild($quadrants);
}

if ($want_lines && $want_spaces) {
  $root->removeChild($lines);
  $root->addChild($lines);
}

##--------------------------------------------------------------
## css


##------ css: default
my $labelsize = .08 * $radius;
my $slabelsize = .02 * $radius;
my $sstroke = .02*$slabelsize;
$defs->addChild(style(<<EOF, 'style css default', id=>'style-default'));
/*-- default style --*/
.rim {
  fill: none;
  stroke: #000000;
  stroke-width: 1;
}
.point {
  fill: #000000;
  stroke: #000000;
  stroke-width: 1;
}
.line {
  stroke: #000000;
  stroke-width: 1;
}
.label {
  font: ${labelsize}px monospace;
}
.space-label {
  font: ${slabelsize}px sans-serif;
  text-decoration: underline;
  fill: #000000;
}
.quadrant {
  fill: none;
  stroke: #000000;
}

.board-template .space {
  stroke: #000000;
  stroke-width: 1;
}
.space.white { fill: #ffffff; }
.space.black { fill: #000000; }

.board-labels .space.white { fill: #f0f0f0; }
.board-labels .space.black { fill: #d8d8d8; }
EOF

##------ css: user
if ($cssfile) {
  open(my $cssfh, "<$cssfile")
    or die("$0: open failed for $cssfile: $!");
  local $/ = undef;
  my $cssbuf = <$cssfh>;
  close($cssfh);
  $defs->addChild(style($cssbuf, 'style css user', id=>'style-user'));
}


##--------------------------------------------------------------
## dump

if ($outfile && $outfile ne '-') {
  $doc->toFile($outfile, 1);
} else {
  $doc->toFH(\*STDOUT, 1);
}
