#!/usr/bin/perl
my $version = 'TheP(aste)B.in CLI Uploader. (v1.3) - http://thepb.in/ - By Louis T. (louist@ltdev.im)';
# License:
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>
use strict;
use warnings;
use IO::Socket;
use File::Basename;
use File::Copy;
use Switch;
use Time::HiRes qw(sleep);
use POSIX qw(strftime);
use Cwd qw(abs_path);
use Digest::MD5 qw(md5_hex);

## Below are required installs.
use File::MimeInfo;

#Config
my $base = "/tmp/"; #where to store temporary files
my $host = "thepb.in"; #domain of the upload server
my $port = 80; # server port (should always be 80)
my $type = "sfw"; # default upload mode
my $delay = 3; #time in seconds to wait before taking screenshots.
my $frames = 4; # Number of images to take with --video. (1-4) [--frames=(1-4)]
my $save = 0; # Save 'temporary' files afer upload. (0=no, 1=yes)
my $width = "400"; # Default Width for video thumbnails.
my $height = "250"; #Default height for video thumbnails.
my $noupload = 0; # Disable uploads. (Good for generating thumbnails?)

my $max_file_size = 'get_max_size'; # Get the maximum file size from TheP(aste)B.in

my @imgs = ();
my @coms = ();
# Check script arguments.
if (scalar(@ARGV) > 0) {
   foreach my $arg (@ARGV) {
      my @arg = split(/=/,$arg); 
      switch ($arg[0]) {
         case {$_[0] eq "--help" or $_[0] eq "-h"} {      
              help(); exit;
         } case "--version" {
              print "$version\n"; exit;
         } case "--get-max-size" {
              print "TheP(aste)B.in reports ",get_max_size()," bytes as the maximum file size.\n"; exit;
         } case {$_[0] eq "--full" or $_[0] eq "-f"} {
              push(@coms,'full');
         } case {$_[0] eq "--area" or $_[0] eq "-a"} {
              push(@coms,'area');
         } case "--video" {
              push(@coms,"video=$arg[1]");
         } case "--img" {
              push(@coms,"img=$arg[1]");
         } case "--sfw" {
              $type = "sfw";
         } case "--nsfw" {
              $type = "nsfw";
         } case "--noupload" {
              $noupload = 1;
         } case "--frames" {
              if ($arg[1] =~ /^[+-]?\d+$/) { $frames = $arg[1]; }
         } case "--delay" {
              if ($arg[1] =~ /^[+-]?\d+$/) { $delay = $arg[1]; }
         } case "--save" {
              if ($arg[1] =~ /^[+-]?\d+$/) { $save = $arg[1]; }
         } case "--tempdir" {
              if (-d $arg[1]) { $base = $arg[1]; }
         } else {
              my $name = basename(abs_path($0));
              print "Unknown command/mode: '$arg[0]' - please check the help ($name --help).\n";
         }
      }
   }
 } else {
   help(); exit;
}
if (@coms && scalar(@coms) > 0) {
   if ($max_file_size eq 'get_max_size') {
      $max_file_size = get_max_size();
   }
   my $date = strftime "%a %b %e %H:%M:%S %Y", gmtime;
   print "STARTTIME: $date\n";
   if (my @line = grep {$_ =~ /^video=/} @coms) {
      if (scalar(@coms) > 1) {
         print "--video called. All other flags will be ignored.\n";
      }
      my @arg = split(/=/,$line[0]);
      video($arg[1]);
    } else {
      foreach my $com (@coms) {
         switch ($com) {
            case "full" {
               push(@imgs,full());
            } case "area" {
               push(@imgs,area());
            } case {$com =~ /^img=/} {
               my @arg = split(/=/,$com);
               if (-e $arg[1] && mimetype($arg[1]) =~ /image.*/) {
                  my $md5 = md5_hex($arg[1]);
                  copy($arg[1],"${base}ThePB-$md5.png") or print "Copy failed: $!\n";
                  if (-e "${base}ThePB-$md5.png") {
                     push(@imgs,"${base}ThePB-$md5.png");
                     print "Marked '",basename($arg[1])," '(ThePB-$md5.png) for upload.\n";
                  }
                } else {
                  my $name = basename($arg[1]);
                  print "Image files only! (Skipping '$name')\n";
               }
            }
         }
      }
   }
 } else {
   help(); exit;
}
if (@imgs && scalar(@imgs) > 0 && $noupload ne 1) {
   send_data(build_binary_data(@imgs));
 } else {
   print "No images to upload. "; print ($noupload eq 1?"('noupload' Enabled!)\n":"\n"); exit;
}
sub area {
    print "Select area on screen in $delay second(s).\n";
    my $md5 = md5_hex(rand());
    my $picture = "${base}ThePB-$md5.png";
    sleep($delay);
    `import "$picture"`;
    if (-e $picture) {
       return $picture;
     } else {
       print "Error finding '$picture', do you have imagemagick installed?\n";
    }
}
sub full {
    print "Generating screenshot in $delay second(s)...\n";
    my $md5 = md5_hex(rand());
    my $picture = "${base}ThePB-$md5.png";
    sleep($delay);
    `import -window root "$picture"`;
    if (-e $picture) {
       return $picture;
     } else {
       print "Error finding '$picture', do you have imagemagick installed?\n";
    }
}
sub video {
    my $file = shift;
    unless (-e $file) {
       print "File '$file' does not exist! Exiting.\n"; exit;
    } 
    my $duration = 0;
    my $mplayer = `mplayer -identify -frames 0 -vc null -vo null -ao null $file 2>&1`;
    if ($mplayer =~ /ID_LENGTH=(\d+)(?:\.)?/) {
       $duration = $1;
     } else {
       print "Could not get duration.\n"; exit;
    }
    if ($mplayer =~ /ID_VIDEO_WIDTH=(\d+)/) {
       $width = $1;
     } else {
       print "Could not get width, falling back to default.\n";
    }
    if ($mplayer =~ /ID_VIDEO_HEIGHT=(\d+)/) {
       $height = $1;
      } else {
       print "Could not get height, falling back to default.\n";
    }
    if ($frames <= 1) { $frames = 2; }
    for (my $i = 0; $i < $frames; $i++) {
        my $md5 = md5_hex(rand());
        my $picture = "${base}ThePB-$md5.png";
        my $loc = rand($duration);
        my $hour =  ($loc/(60*60))%24;
        my $min = ($loc/60)%60;
        my $sec = $loc%60;
        my $time = "$hour:$min:$sec";
        `mplayer -nosound -ss $time -vf screenshot -frames 1 -vo png:z=9 -vf scale=$width:$height $file > /dev/null 2>&1 && mv 00000001.png $picture`;
        if (-e $picture) {
           push(@imgs,$picture);
        }
    }
}
sub build_binary_data {
    my @files = @_;
    my $line = "";
    my $time = time();
    my $boundry = "------multipartformboundary$time";
    my $max = 0;
    if (scalar(@files) > 6) { 
       print "Trying to upload too many files. Only sending 6.\n";
       $max = 5;
     } else {
       $max = (scalar(@files))-1;
    }
    for (my $i = 0; $i <= $max; $i++) {
        my $file = $files[$i];
        my ($binary,$size) = get_binary_data($files[$i]);
        if ($binary ne 1) {
           my $mime = mimetype($file);
           my $img = basename($file);
           $line .= "--$boundry\r\nContent-Disposition: form-data; name=\"user_file[]\"; filename=\"$file\"\r\n";
           $line .= "Content-Type: $mime\r\n\r\n$binary\r\n--$boundry\r\n";
           print "Added '$img' to upload list successfully.\n";
        }
        if ($save != 1 && -e $file) {
           unlink($file) or print "Unlink failed: $!\n";
        }
    }
    if (length($line)>1) { return ($line,length($line),$boundry); } else { return (1); }
}
sub send_data {
    my @data = @_;
    if ($data[0] ne 1) {
       print "Connecting to TheP(aste)B.in\n";
       my $server = IO::Socket::INET->new(PeerAddr=>$host,PeerPort=>$port);
       if (defined($server)) {
          print "Connected to TheP(aste)B.in - Sending.\n";
          my $header = "POST /upload.php?nojs&type=$type HTTP/1.1\r\n";
          $header .= "Host: $host\r\n";
          $header .= "Content-Type: multipart/form-data; boundary=$data[2]\r\n";
          $header .= "Content-Length: $data[1]\r\n\r\n";
          print $server "$header$data[0]";
          while (<$server>) {
                if ($_ =~ /^(OK|NO):/) { parse_data($_); }
                if ($_ =~ /^END/) { close($server); last; }
          }
          my $date = strftime "%a %b %e %H:%M:%S %Y", gmtime;
          print "ENDTIME: $date\n";
        } else {
          print "Could not connect to TheP(aste)B.in\n";
       }
     } else {
       print "No data to send.\n";
    }
}
sub parse_data {
    my @data = split(/: /,$_);
    if ($data[0] eq "OK") {
       foreach (split(/@/,$data[1])) {
          chomp($_);
          print "Your image is at: http://$host/$_\n";
       }
     } else {
       print "$data[1]\n";
    }
}
sub get_binary_data {
    my $file = shift;
    unless (defined($file) && -e $file) {
       print "$file does not exist!\n"; return 1;
    }
    my $name = basename($file);
    if (mimetype($file) =~ /image.*/) {
       my $size = (stat($file))[7] || die "stat($file): $!\n";
       if ($size > $max_file_size) {
          print "ERROR: Image ($name) is too large! ($size bytes/Max: $max_file_size)\n"; return 1;
       }
       open FILE, $file or die $!;
       binmode FILE;
       my ($buf, $data, $n);
       while (($n = read FILE, $data, 1024) != 0) {
          $size += $n; $buf .= $data;
       } 
       close(FILE);
       return ($buf,$size);
     } else {
       print "Image files only! Skipping '$name'\n"; return 1;
    }
}
sub get_max_size {
    my $server = IO::Socket::INET->new(PeerAddr=>$host,PeerPort=>$port);
    if (defined($server)) {
       print $server "GET /upload.php?maxsize HTTP/1.1\r\nHost: $host\r\n\r\n";
       my $size = 0;
       while (<$server>) {
             if ($_ =~ /^OK:/) { $size = (split(/: /,$_))[1]; }
             if ($_ =~ /^END/) { close($server); last; }
       }
       if ($size == 0) {
          print "Could not get max size from TheP(aste)B.in\n"; exit;
        } else {
          chomp($size); return $size;
       }
     } else {
       print "Could not connect to TheP(aste)B.in\n"; exit;
    }
}
sub help {
    my $name = basename(abs_path($0));
    print "$version\n\n$name flags[=params] [options]\n\n";
    print "Flags:\n-f, --full - Take a fullscreen screenshot and then upload to TheP(aste)B.in\n";
    print "-a, --area - Screenshot selected area and then upload to TheP(aste)B.in\n";
    print "--img=/path/to/image.ext - Upload selected image to TheP(aste)B.in Path to image is required.\n";
    print "--video=/path/to/video.ext - Upload thumbnails of a video to TheP(aste)B.in (Disables other flags.)\n";
    print "--get-max-size - Get the maximum file size from TheP(aste)B.in\n";
    print "--version - Display version.\n-h, --help - Show this.\n";
    print "\nOptions:\n--sfw - Mark upload as safe for work. "; print ($type eq 'sfw'?"(Current default.)\n":"\n");
    print "--nsfw - Mark upload as an adult (18+) image. "; print ($type eq 'nsfw'?"(Current default.)\n":"\n");
    print "--frames=[1-4] - Number of thumbnails to make from a video. (Current default: $frames)\n";
    print "--save=[0-1] - Save 'temporary' files. (0=no, 1=yes) (Current default: $save)\n";
    print "--delay=seconds - How long to wait before taking screenshots. (Current default: $delay)\n";
    print "--tempdir=/path/to/temp/location/ - Where to make 'temporary' files. (Current default: $base)\n";
    print "--noupload - Do not upload to TheP(aste)B.in "; print ($noupload eq 1?"(Current default: Enabled.)\n":"(Current default: Disabled.)\n");
    print "\nExample(s):\n$name --img=/path/to/nakedlady.png --nsfw\n";
    print "$name --video=/path/to/awesomeness.avi\n$name --video=/path/to/that_one_awesome-video.mp4 --frames=3\n";
    print "$name --video=/path/to/that_one_awesome-video.mp4 --save=1 --tempdir=\$HOME/Desktop/\n";
    print "$name --img=/path/to/thisone.png --img=/path/to/that/other/one.png\n$name -f -f -f --delay=6 --sfw\n";
    print "$name -f -a -a --img=/path/to/this/one/nude.png --delay=4 --nsfw\n\n";
    print "Report any issues to louist\@ltdev.im\n";
}
