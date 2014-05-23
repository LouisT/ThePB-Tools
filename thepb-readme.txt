TheP(aste)B.in CLI Paster. (v1.3) - http://thepb.in/ - By Louis T. (louist@ltdev.im)

CHANGES:
  v1.3 (Sun Sep 15 2013):
     - Disable SSL. Due to using CloudFlare, I can't provide SSL at this time.
     - Added optional delete link display. (--dlink)
  v1.2 (Mon Dec 10 2012):
     - Added clipboard support. (-c or --clip)
     - Added paste description support. (--desc="The Description")
  v1.1 (Sat Nov 17 2012):
     - Added LWP::Protocol::https for SSL support. (--ssl)
  v1.0 (Tue 23 Oct 2012):
     - First release!

*******
NOTICE:
   This assumes your perl install is in /usr/bin/perl
   Replace the shebang in 'thepb.txt' if it's located
   in a different location!
*******

- Required CPAN modules -
JSON            - http://search.cpan.org/dist/JSON/
WWW::Mechanize  - http://search.cpan.org/dist/WWW-Mechanize/

- Optional CPAN modules -
LWP::Protocol::https - http://search.cpan.org/dist/LWP-Protocol-https/

[Local CPAN]
  cpan
  install JSON WWW::Mechanize
  install LWP::Protocol::https (optional)

[Global CPAN]
  sudo cpan
  install JSON WWW::Mechanize
  install LWP::Protocol::https (optional)

-------- INSTALL --------
[optional]
  For clipboard access, install xclip. (http://sourceforge.net/projects/xclip/)

[Linux Local Install]
  mkdir ~/bin
  wget -O ~/bin/thepb http://thepb.in/tools/official/thepb.txt
  chmod +x ~/bin/thepb

Optional if you don't have ~/bin setup already:
  echo 'PATH=$PATH:$HOME/bin' >> .bashrc && . ~/.bashrc

Don't forget to reload bash. (. ~/.bashrc)

[Linux Global Install]
  sudo wget -O '/usr/local/bin/thepb' http://thepb.in/tools/official/thepb.txt
  sudo chmod +x /usr/local/bin/thepb

[Others]
  I have no idea. I'll try and figure it out at some point.

------- UNINSTALL -------
[Linux Local Uninstall]
  rm -rf ~/.thepb/ ~/bin/thepb

[Linux Global Uninstall]
  sudo rm /usr/local/bin/thepb && rm -rf ~/.thepb/

[Others]
  I have no idea. I'll try and figure it out at some point.

--------- SETUP ---------
1) Register at http://thepb.in/p/auth
2) Get your API key from http://thepb.in/p/userinfo
3) Set your API key:
   thepb --apikey=<APIKEY> --save

--------- USAGE ---------
Usage: thepb flags[=params] [options]

-h, --help             - Display this message.
-v, --version          - Display the script version.
-p, --private          - Set the paste to private.
-s, --save             - Save your config settings.
-c, --clip             - Paste content from clipboard.
    --apikey=<APIKEY>  - Your API key. (http://thepb.in/p/userinfo)
    --mode=<mode>      - Set the request mode. (paste, edit, delete)
    --file=<file>      - The file you wish to paste/edit from.
    --id=<id>          - ID of the paste you want to edit or delete.
    --del=<del>        - The deletion key provided after pasting.
    --lang=<lang>      - The language ID you wish to paste in. (http://thepb.in/p/direct OR --listlangs)
    --pass=<pass>      - Password protect a paste.
    --sub=<sub>        - The subdomain to use when pasting. (http://thepb.in/p/direct OR --listlangs)
    --desc=<desc>      - Set a small description of your paste.
    --dlink            - Display the link to delete the paste.
    --keyinfo          - List the information about your API key.
    --listlangs        - List all of the available languages in ID form. (--lang=<id>)
    --debug            - Print the content returned from TheP(aste)B.in

Examples:
  thepb --file=/path/to/file
  thepb --file=/path/to/file -p
  cat /proc/cpuinfo | thepb
  ifconfig | thepb -p --pass=apassword
  ps x | thepb --sub=text

Report any issues to louist@ltdev.im
