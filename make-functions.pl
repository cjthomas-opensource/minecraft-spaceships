#!/usr/bin/perl

#
# Includes

use strict;
use warnings;



#
# Constants


# Help screen.
my ($help_screen);
$help_screen = << 'Endofblock';

Usage:  make-functions.pl  (target directory)

Endofblock



#
# Testing switches.


# "Smoke test" switch, generating the fewest test cases.
my ($smoke_test);
$smoke_test = 0;

# "Version" switch, forcing older versions.
# Use '' or 'latest' for the current version.
my ($force_version);
$force_version = '';
#$force_version = '1.15';



#
# Configuration variables.


# Version.
my ($version);
if ( '1.15' eq $force_version )
{ $version = '20200622'; }
else
{ $version = '20240107'; }


# Ticks to wait before doing anything.
my ($tickdelay);
$tickdelay = 20;


# Movement distances.
# These need to be multiples or factors of 16, and within chunk-loading
# distance. Ones smaller than the spaceship size are dropped.

my (@distlist);

# Baseline version.
#@distlist = ( 16, 32, 64 );
# Extended version. Cap at 64, even though 96 should work.
@distlist = ( 4, 8, 16, 32, 48, 64 );

# Smoke test version.
if ($smoke_test)
{ @distlist = ( 32 ); }


# Space Bunny configuration.

my ($bunnyreportname, $bunnyrealname, $bunnytype);
$bunnyreportname = 'Warp Bunny';
# This should be something that nobody would accidentally duplicate.
# Or deliberately duplicate without reading this script or the functions.
$bunnyrealname = 'SpaceBunnyEntity';

# This was originally a rabbit, but that resulted in spaceships raining
# rabbit bits down underneath them, causing some players distress.
# With markers, check all other scripts for interactions in case one of them
# decides to affect all markers in the world while a spaceship is active.
#$bunnytype = 'rabbit';
$bunnytype = 'marker';

# NBT tag and NBT selector for Space Bunny entities.
# This also includes an "everything except space bunnies" selector.
# NOTE - 1.20.4 changed the way text selection works.
my ($bunnytag, $bunnyselector, $bunnynonselector);
if ( '1.15' eq $force_version )
{
  $bunnytag = 'CustomName:\'{"text":"' . $bunnyrealname . '"}\'';
  $bunnyselector = 'type=' . $bunnytype . ',nbt={' . $bunnytag . '}';
  $bunnynonselector = 'type=!' . $bunnytype;
}
else
{
  $bunnytag = 'CustomName:\'"' . $bunnyrealname . '"\'';
  $bunnyselector = 'type=' . $bunnytype . ',nbt={' . $bunnytag . '}';
  $bunnynonselector = 'nbt=!{' . $bunnytag . '}';
}



#
# Functions


# Writes the specified string to a file.
# Arg 0 is the filename to write to.
# Arg 1 is the text to write.
# No return value.

sub WriteFile
{
  my ($oname, $text);

  $oname = $_[0];
  $text = $_[1];

  if (!( (defined $oname) && (defined $text) ))
  {
    print "### [WriteFile]  Bad arguments.\n";
  }
  elsif (!open(OFILE, ">$oname"))
  {
    print "### [WriteFile]  Couldn't write to \"$oname\".\n";
  }
  else
  {
    print OFILE $text;
    close(OFILE);
  }
}



# This generates scripts for one specific motion of a ship of one size.
# Arg 0 is the base directory to put scripts in.
# Arg 1 is the subdirectory for this ship size's scripts.
# Arg 2 is the ship width (X).
# Arg 3 is the ship height (Y).
# Arg 4 is the ship depth (Z).
# Arg 5 is the X motion offset ('' or 0 for none).
# Arg 6 is the Y motion offset ('' or 0 for none).
# Arg 7 is the Z motion offset ('' or 0 for none).
# Arg 8 is a unique label to use for this motion.
# No return value.

sub GenerateMovement
{
  my ($outdir, $casedir, $xsize, $ysize, $zsize, $dx, $dy, $dz, $label);
  my ($prefix);
  my ($xmid, $ymid, $zmid, $radius);

  $outdir = $_[0];
  $casedir = $_[1];
  $xsize = $_[2];
  $ysize = $_[3];
  $zsize = $_[4];
  $dx = $_[5];
  $dy = $_[6];
  $dz = $_[7];
  $label = $_[8];

  if (!( (defined $outdir) && (defined $casedir)
    && (defined $xsize) && (defined $ysize) && (defined $zsize)
    && (defined $dx) && (defined $dy) && (defined $dz)
    && (defined $label) ))
  {
    print "### [GenerateMovement]  Bad arguments.\n";
  }
  else
  {
    $prefix = "$casedir/$label";

    # Entry point.
    # This is a mutex wrapper for the real entry point.
    WriteFile( "$outdir/$prefix" . '.mcfunction',
      "execute if entity \@e[$bunnyselector] run"
      . " say $bunnyreportname is busy!\n"
      . "execute unless entity \@e[$bunnyselector] run"
      . " function cjt_ship:$prefix" . "_real\n" );

    # Real entry point.
    WriteFile( "$outdir/$prefix" . '_real.mcfunction',
      "function cjt_ship:makebunny\n"
      . 'schedule function cjt_ship:' . $prefix . 'copy ' . $tickdelay . "\n"
      . 'schedule function cjt_ship:' . $prefix . 'tport '
      . ($tickdelay + 2) . "\n"
      . 'schedule function cjt_ship:' . $casedir . '/erase '
      . ($tickdelay + 4) . "\n"
      . 'schedule function cjt_ship:killbunny ' . ($tickdelay + 6) . "\n"
    );

    # Copy helper.
    # NOTE - Do not use "replace move". That leaves the passengers falling,
    # and the displacement will carry over during the teleport.
    WriteFile( "$outdir/$prefix" . 'copy.mcfunction',
      "execute at \@e[$bunnyselector] run clone ~ ~ ~ ~" . ($xsize - 1)
      . " ~" . ($ysize - 1) . " ~" . ($zsize - 1)
      . " ~$dx ~$dy ~$dz\n" );

    # Teleport helper.
    # NOTE - Don't move the SpaceBunny. SpaceBunny has to stay where it is.
    # Do move all other critters, in case horses or dogs are on board.
    # Remember "at @s"! Otherwise everything moves to the same location.

    # FIXME - Bedrock Edition can use tilde notation in a volume selector.
    # Java Edition can't, so we have to do radius from a midpoint.
    # This will pull along entities that are near but not in the ship.
    $xmid = ($xsize - 1) * 0.5;
    $ymid = ($ysize - 1) * 0.5;
    $zmid = ($zsize - 1) * 0.5;
    $radius = 0.5 * sqrt($xsize * $xsize + $ysize * $ysize + $zsize * $zsize);
    $radius = sprintf('%.2f', $radius);

    WriteFile( "$outdir/$prefix" . 'tport.mcfunction',
      "execute at \@e[$bunnyselector] positioned ~$xmid ~$ymid ~$zmid"
      . ' as @e[' . $bunnynonselector . ',distance=..' . $radius . ']'
      . ' at @s run teleport @s' . " ~$dx ~$dy ~$dz\n" );
  }
}


# Entry point for generating scripts for a given ship size.
# NOTE - This supports different X and Z even though our test cases have
# them the same.
# Arg 0 is the directory to put scripts in.
# Arg 1 is a prefix label for the scripts (identifying the ship size).
# Arg 2 is the width (X).
# Arg 3 is the height (Y).
# Arg 4 is the depth (Z). (If undef, defaults to width.)
# No return value.

sub GenerateScripts
{
  my ($outdir, $label, $xsize, $ysize, $zsize);
  my ($cmd, $result);
  my ($thisdist);
  my ($xmid, $ymid, $zmid, $radius);

  $outdir = $_[0];
  $label = $_[1];
  $xsize = $_[2];
  $ysize = $_[3];
  $zsize = $_[4];

  if (!(defined $zsize))
  { $zsize = $xsize; }

  if (!( (defined $outdir) && (defined $label)
    && (defined $xsize) && (defined $ysize) && (defined $zsize) ))
  {
    print "### [GenerateScripts]  Bad arguments.\n";
  }
  else
  {
    # Progress banner, since this takes a while (maybe due to shell calls?).
    print ".. Generating \"$label\"...\n";


    # NOTE - Minecraft does not like more than one underscore in a name.
    # The approved way of grouping functions is subfolders.

    # Make a folder for this set of scripts.
    $cmd = "mkdir $outdir/$label";
    $result = `$cmd`;


    # Calculate dimensions for the entity selection volume.
    $xmid = ($xsize - 1) * 0.5;
    $ymid = ($ysize - 1) * 0.5;
    $zmid = ($zsize - 1) * 0.5;
    $radius = 0.5 * sqrt($xsize * $xsize + $ysize * $ysize + $zsize * $zsize);
    $radius = sprintf('%.2f', $radius);


    # The "erase" script is common to all.
    WriteFile( "$outdir/$label/erase.mcfunction",

      # First, destroy blocks in the target volume.
      "execute at \@e[$bunnyselector] run fill ~ ~ ~ ~" . ($xsize - 1)
        . " ~" . ($ysize - 1) . " ~" . ($zsize - 1) . " air\n"

      # Next, destroy all item entities in the target volume.
      # Borrow the teleport volume specifier, since we can't use ~ notation.
      . "execute at \@e[$bunnyselector] positioned ~$xmid ~$ymid ~$zmid"
      . ' run kill @e[type=item,distance=..' . $radius . "]\n"
    );


    # Per-direction, per-distance scripts.
    foreach $thisdist (@distlist)
    {
      if ($thisdist >= $xsize)
      {
        GenerateMovement($outdir, $label, $xsize, $ysize, $zsize,
          -$thisdist, '', '', "west$thisdist");
        GenerateMovement($outdir, $label, $xsize, $ysize, $zsize,
          $thisdist, '', '', "east$thisdist");
      }

      if ($thisdist >= $ysize)
      {
        GenerateMovement($outdir, $label, $xsize, $ysize, $zsize,
          '', -$thisdist, '', "down$thisdist");
        GenerateMovement($outdir, $label, $xsize, $ysize, $zsize,
          '', $thisdist, '', "up$thisdist");
      }

      if ($thisdist >= $zsize)
      {
        GenerateMovement($outdir, $label, $xsize, $ysize, $zsize,
          '', '', -$thisdist, "north$thisdist");
        GenerateMovement($outdir, $label, $xsize, $ysize, $zsize,
          '', '', $thisdist, "south$thisdist");
      }
    }
  }
}



#
# Main Program

my ($outdir);

$outdir = $ARGV[0];

if (!(defined $outdir))
{
  print $help_screen;
}
else
{
  WriteFile("$outdir/version.mcfunction",
    "say CJT spaceship scripts version $version.\n");

  # FIXME - This should also be invisible, but that's tricky to get working.
  # NOTE - The rabbit needs to be invulnerable. Otherwise operations fail
  # when the rabbit dies mid-transport.
  # Markers default to being invisible and invulnerable, but critters need
  # specific tags. Add them even if we're using a marker.
  WriteFile("$outdir/makebunny.mcfunction",
    "summon $bunnytype ~ ~ ~ {NoAI:1,Invulnerable:1,$bunnytag}\n");

  WriteFile("$outdir/killbunny.mcfunction", "kill \@e[$bunnyselector]\n");

  if ($smoke_test)
  {
    # Smoke test.
    GenerateScripts($outdir, "disc8", 8, 4);
  }
  else
  {
    # Full version.

    GenerateScripts($outdir, "cube8", 8, 8);
    GenerateScripts($outdir, "cube16", 16, 16);
    GenerateScripts($outdir, "cube32", 32, 32);

    GenerateScripts($outdir, "tower16", 8, 16);
    GenerateScripts($outdir, "tower32", 16, 32);

    GenerateScripts($outdir, "disc8", 8, 4);
    GenerateScripts($outdir, "disc16", 16, 8);
    GenerateScripts($outdir, "disc32", 32, 16);
  }
}


#
# This is the end of the file.
