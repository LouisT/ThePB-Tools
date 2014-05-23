#!/usr/bin/perl
my $version = 'TheP(aste)B.in CLI Paster. (v1.3) - http://thepb.in/ - By Louis T. (louist@ltdev.im)';
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
use Switch;
use Module::Load::Conditional qw[can_load];
use WWW::Mechanize;
use JSON -support_by_pp;

my $confdir = "$ENV{HOME}/.thepb"; #Home directory! Should not need to change. (linux only)
my $conffile = "$confdir/config.json"; #The config file.
my $apiurl = "thepb.in/api"; #The API url.
my $proto = "http://"; # Default (--ssl)

my %config = (
   "apikey",0,
   "mode","paste",
   "lang","text",
   "priv",0,
   "sub",0,
   "pass",0,
); #Config settings! read_config overwrites these!

if (-d $confdir && -e $conffile) {
   if (!read_config()) {
      die "Could not read config!";
   }
};

my %opts = ("run",0,"file",0,"save",0,"pass",0,"debug",0,"clip",0,"desc",0,"sdel",0); #Random settings!
# Parse arguments like a boss.
if (scalar(@ARGV) > 0) {
   foreach my $arg (@ARGV) {
      my @arg = split(/=/,$arg); 
      switch ($arg[0]) {
         case {$_[0] eq "--help" or $_[0] eq "-h"} {      
              help();
              exit;
         }
         case {$_[0] eq "--version" or $_[0] eq "-v"} {
              output("$version\n");
              exit;
         }
         case {$_[0] eq "--private" or $_[0] eq "-p"} {
              $config{"priv"} = 1;
         }
         case "--debug" {
              $opts{"debug"} = 1;
         }
         case "--pass" {
              if (defined($arg[1]) && length($arg[1]) > 1) {
                 $opts{"pass"} = $arg[1];
              }
         }
         case "--apikey" {
              if (check_key($arg[1])) {
                 $config{"apikey"} = $arg[1];
                 output("API Key: $arg[1]");
               } else {
                 output("Invalid --apikey supplied!");
                 exit;
              }
         }
         case "--keyinfo" {
              $opts{"runget"} = 1;
         }
         case "--listlangs" {
              $opts{"listlangs"} = "";
              $opts{"runget"} = 1;
         }
         case "--sub" {
              if (defined($arg[1]) && length($arg[1]) > 1) {
                 $config{"sub"} = $arg[1];
              }
         }
         case "--desc" {
              if (defined($arg[1]) && length($arg[1]) > 1) {
                 $opts{"desc"} = $arg[1];
              }
         }
         case "--mode" {
              if (defined($arg[1]) && length($arg[1]) > 1) {
                 if ($arg[1] =~ m/(delete|edit|paste)/) {
                    $config{"mode"} = $arg[1];
                  } else {
                    output("Invalid --mode provided!");
                    exit;
                 }
              }
         }
         case {$_[0] eq "--clip" or $_[0] eq "-c"} {
              if (open my $XCLIP, 'xclip -o|') {
                 $opts{"run"} = 1;
                 $opts{"clip"} = 1;
               } else {
                 output("","[WARNING] Please install 'xclip' to use the clipboard feature.",""); exit;
              }
         }
         case "--ssl" {
              # Due to using CloudFlare, I can't provide SSL at this time.
              output("","[WARNING] SSL has been temporarily disabled. Sorry for the inconvenience!",""); exit;
#              my $optional = {'LWP::Protocol::https'=>undef};
#              if (can_load(modules => $optional)) {
#                 $proto = "https://";
#               } else {
#                 output("","[WARNING] Module 'LWP::Protocol::https' was not loaded - no SSL support!",""); exit;
#              }
         }
         case "--dlink" {
              $opts{"sdel"} = 1;
         }
         case "--del" {
              if (defined($arg[1]) && length($arg[1]) > 1) {
                 $config{"mode"} = "delete";
                 $opts{"delkey"} = $arg[1];
                 $opts{"run"} = 1;
              }
         }
         case "--id" {
              if (defined($arg[1]) && length($arg[1]) > 1) {
                 $opts{"id"} = $arg[1];
              }
         }
         case "--lang" {
              if (defined($arg[1]) && length($arg[1]) > 1) {
                 $config{"lang"} = $arg[1];
              }
         }
         case {$_[0] eq "--save" or $_[0] eq "-s"} {
              $opts{"save"} = 1;
         }
         case "--file" {
              if ($opts{"file"} eq 0) {
                 my $file = $arg[1];
                 if (defined($file) && -e $file) {
                    $opts{"file"} = $file;
                  } else {
                    output("Invalid file!");
                    exit;
                 }
              }
              $opts{"run"} = 1;
         }
      }
   }
   if (!-t STDIN) {
      $opts{"run"} = 1;
   }
 } else {
   if (-t STDIN) {
      help();
      exit;
    } else {
      $opts{"run"} = 1;
   }
}

$apiurl = $proto.$apiurl; # Use SSL?

if (defined $opts{"runget"}) {
   get_data();
   exit;
}
if ($opts{"save"} eq 1) {
   if (save_config() eq 1) {
      output("Save successful.");
   }
};
if ($opts{"run"} eq 1) {
   if ($config{"mode"} eq "delete") {
      send_data();
    } else {
      my $content = get_content();
      if ($content ne 0) {
         if (length($content) > 15) {
            send_data($content);
          } else {
            output("Invalid content length! (<15)");
            return 0;
         }
       } else {
         output("Invalid content!");
      }
   }
 } else {
   if ($opts{"save"} ne 1) {
    #  help();
   }
}

#Submit data to thepb's API.
sub send_data {
    my %post;
    if (defined $config{"apikey"} && check_key($config{"apikey"})) {
       if (defined $_[0]) {
          $post{"paste"} = $_[0];
       }
       $post{"apikey"} = $config{"apikey"};
       if (defined $config{"mode"}) {
          $post{"mode"} = $config{"mode"};
       }
       if (defined $post{"mode"}) {
          if ($post{"mode"} =~ m/(delete|edit)/ && !defined $opts{"id"}) {
             output("--id is required for this mode!");
             exit;
          }
          if (defined $opts{"id"}) {
             $post{"id"} = $opts{"id"};
          }
          if ($post{"mode"} eq "paste" or $post{"mode"} eq "edit") {
             if (defined $config{"lang"}) {
                $post{"lang"} = $config{"lang"};
             }
             if (defined $config{"priv"} && $config{"priv"} eq 1) {
                $post{"priv"} = "true";
             }
             if (defined $config{"sub"} && $config{"sub"} ne 0) {
                $post{"sub"} = $config{"sub"};
             }
             if (defined $opts{"pass"} && $opts{"pass"} ne 0) {
                $post{"pass"} = $opts{"pass"};
             }
             if (defined $opts{"desc"} && $opts{"desc"} ne 0) {
                $post{"desc"} = $opts{"desc"};
             }
          } elsif ($post{"mode"} eq "delete") {
             if (defined $opts{"delkey"}) {
                $post{"delkey"} = $opts{"delkey"};
              } else {
                output("--del is required for delete mode!");
                exit;
             }
          } else {
            output("Invalid --mode supplied!");
            exit;
          }
        } else {
          output("No mode provided!");
          exit;
       }
     } else {
       output("API key is required!");
       return 0;
    }
    my $browser = WWW::Mechanize->new();
    eval {
       $browser->post($apiurl,\%post);
    };
    if ($@) { die "POST error! ($!)"; };
    my $status = $browser->status();
    if ($status eq 200) {
       eval {
          my $bdata = $browser->content();
          if ($opts{"debug"} eq 1) {
             output("--- DEBUG ---",$bdata,"--- DEBUG ---"," ");
          }
          my %content = %{decode_json($bdata)};
          if (!defined $content{"error"}) {
             if ($content{"mode"} ne "delete") {
                my $url = $content{"url"};
                my $key = $content{"key"};
                my $durl = $content{"delurl"};
                my $dkey = $content{"del"};
                output("URL: $url (ID: $key)");
                if ($opts{"sdel"} eq 1) {
                   output("Delete: $durl (Delete: $dkey)");
                };
                if (defined $content{"pass"}) {
                   my $pass = $content{"pass"};
                   output("Password: $pass");
                }
              } else {
                my $msg = $content{"msg"};
                output("Result: $msg");
             }
           } else {
             my $error = $content{"error"};
             output("ERROR: $error");
          }
       };
       if ($@) { die "JSON error! ($!)"; };
     } else {
       output("Invalid status returned! ($status)");
    }
};

sub get_data {
    my %get;
    if (defined $config{"apikey"} && check_key($config{"apikey"})) {
       my $apikey = $config{"apikey"};
       $apiurl = "$apiurl?apikey=$apikey";
       if (defined $opts{"listlangs"}) {
          $apiurl .= "&langs";
          $opts{"count"} = 0;
       }
       my $browser = WWW::Mechanize->new();
       eval {
          $browser->get($apiurl);
       };
       if ($@) { die "GET error! ($!)"; };
       my $status = $browser->status();
       if ($status eq 200) {
          eval {
             my $bdata = $browser->content();
             if ($opts{"debug"} eq 1) {
                output("--- DEBUG ---",$bdata,"--- DEBUG ---"," ");
             }
             my %content = %{decode_json($bdata)};
             foreach my $key (sort keys %content) {
                if (defined $opts{"listlangs"}) {
                   $opts{"listlangs"} .= "$key" . (" ") x (20-length($key));
                   $opts{"count"} += 1;
                   if ($opts{"count"} >= 8) {
                      output($opts{"listlangs"});
                      $opts{"count"} = 0;
                      $opts{"listlangs"} = "";
                   }
                 } else {
                   my $info = $content{$key};
                   output("$key: $info");
                }
             }
             if (defined $opts{"listlangs"} && length($opts{"listlangs"}) > 0) {
                output($opts{"listlangs"});
             }
          };
          if ($@) { die "JSON error! ($!)"; };
        } else {
          output("Invalid status returned! ($status)");
       }
     } else {
       output("No API key set! (--apikey)");
    }
};

#Read from STDIN or a file!
sub get_content {
    my $content = "";
    my $file = $opts{"file"};
    my $clip = $opts{"clip"};
    if (defined($clip) && $clip eq 1) {
       $content = getclip();
     } elsif (!defined($file) || $file eq 0) {
       while (defined(my $line = <STDIN>)) {
             $content .= $line;
       }
     } else {
       if (-e $file) {
          {
            local $/; #enable slurp
            open my $fh, "<", "$file";
            $content = <$fh>;
            close($fh);
          }
       }
    }
    chomp($content);
    if (length($content) >= 15) {
       return $content;
     } else {
       return 0;
    }
};

# use xclip to read from the clipboard
sub getclip {
    for (qw(primary buffer clipboard secondary)) {
        my ($selection) = $_;
        my $cmd = "xclip -o -selection $selection|";
        open my $exe, $cmd or die "Couldn't run $cmd: $!\n";
        my @lines = <$exe>;
        s/\r$// for @lines; 
        my $output = join '', @lines;
        return $output if length $output;
    }
    undef;
}

#  Possibly add a logging method here?
#  (~/.thepb/logs/log-<DATE>.txt)
sub output {
    foreach my $out (@_) {
       print "$out\n";
    }
};

# (~/.thepb/config.json)
sub gen_config {
    if (! -d $confdir) {
       output("Creating config folder... ($confdir)");
       unless(mkdir($confdir, 0755)) {
          output("Unable to create $confdir");
          return 0;
       }
    }
    if (! -e $conffile) {
       output("Creating config file... ($conffile)");
       if (write_config() ne 1) {
          output("Error creating config file! ($conffile)");
          return 0;
       }
    }
    if (-w $conffile && -r $conffile) {
       return 1;
    }
    return 0;
};

# (~/.thepb/config.json)
sub read_config {
    if (-d $confdir && -e $conffile) {
       my $json;
       {
         local $/; #enable slurp
         open my $fh, "<", "$conffile";
         $json = <$fh>;
         close($fh);
       }
       if (length($json) == 0) {
          output("Config file is empty!");
          return 0;
       }
       %config = %{decode_json($json)};
       if (check_key($config{"apikey"}) ne 1) {
          output("API key is missing! Might want to recreate your config.");
          return 0;
       }
       return 1;
     } else {
       output("Config does not exist, creating it!");
       return gen_config();
    }
};

# (~/.thepb/config.json)
sub write_config {
    if (! open (CONF, ">$conffile")) {
       output("Error opening $conffile!");
       return 0;
    }
    if (! print CONF encode_json \%config) {
       output("Error writing config file! ($conffile)");
       return 0;
    }
    close (CONF);
    if (! -e $conffile) {
       return 0;
    }
    return 1;
};

# (~/.thepb/config.json)
sub save_config {
    if (! -d $confdir || ! -e $conffile) {
       if (gen_config() eq 1) {
          output("Done generating config.");
          return 1;
        } else {
          output("There was an error generating config!","Please check your config dir! ($confdir)");
          exit;
       }
     } else {
       return write_config();
    }
}

#Check for a UUIDv4 api key
sub check_key {
    if (defined $_[0]) {
       return $_[0] =~ qr/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/is;
    }
    return 0;
};

#Display help...
sub help {
    output($version," ","Usage: thepb flags[=params] [options]");
    output("Setup: thepb --apikey=<APIKEY> --save","");
    output("-h, --help             - Display this message.");
    output("-v, --version          - Display the script version.");
    output("-p, --private          - Set the paste to private.");
    output("-s, --save             - Save your config settings.");
    output("-c, --clip             - Paste content from clipboard.");
# Due to using CloudFlare, I can't provide SSL at this time.
# output("    --ssl              - Use SSL. (https://thepb.in/)");
    output("    --apikey=<APIKEY>  - Your API key. (http://thepb.in/p/userinfo)");
    output("    --mode=<mode>      - Set the request mode. (paste, edit, delete)");
    output("    --file=<file>      - The file you wish to paste/edit from.");
    output("    --id=<id>          - ID of the paste you want to edit or delete.");
    output("    --del=<del>        - The deletion key provided after pasting.");
    output("    --lang=<lang>      - The language ID you wish to paste in. (http://thepb.in/p/direct OR --listlangs)");
    output("    --pass=<pass>      - Password protect a paste.");
    output("    --sub=<sub>        - The subdomain to use when pasting. (http://thepb.in/p/direct OR --listlangs)");
    output("    --desc=<desc>      - Set a small description of your paste.");
    output("    --dlink            - Display the link to delete the paste.");
    output("    --keyinfo          - List the information about your API key.");
    output("    --listlangs        - List all of the available languages in ID form. (--lang=<id>)");
    output("    --debug            - Print the content returned from TheP(aste)B.in","");
    output("Examples:","  thepb --file=/path/to/file","  thepb --file=/path/to/file -p","  cat /proc/cpuinfo | thepb");
    output("  ifconfig | thepb -p --pass=apassword","  ps x | thepb --sub=text","");
    output("Report any issues to louist\@ltdev.im");
};
