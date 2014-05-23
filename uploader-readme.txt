TheP(aste)B.in CLI Uploader. (v1.3) - http://thepb.in/ - By Louis T. (louist@ltdev.im)
-
Required CPAN modules:
File::MimeInfo - http://search.cpan.org/~pardus/File-MimeInfo-0.15/lib/File/MimeInfo.pm
-
Required programs:
ImageMagick - http://www.imagemagick.org/script/index.php
   - 'import' - http://www.imagemagick.org/script/import.php (Used for screenshots.)
-
Optional programs:
mplayer - (http://www.mplayerhq.hu/design7/news.html) (Used for video thumbnail generation.)

--
Usage:
* Might want to 'chmod +x upload' *

upload flags[=params] [options]

Flags:
-f, --full - Take a fullscreen screenshot and then upload to TheP(aste)B.in
-a, --area - Screenshot selected area and then upload to TheP(aste)B.in
--img=/path/to/image.ext - Upload selected image to TheP(aste)B.in Path to image is required.
--video=/path/to/video.ext - Upload thumbnails of a video to TheP(aste)B.in (Disables other flags.)

Options:
--sfw - Mark upload as safe for work.
--nsfw - Mark upload as an adult (18+) image. 
--frames=[1-4] - Number of thumbnails to make from a video.
--save=[0-1] - Save 'temporary' files. (0=no, 1=yes)
--delay=seconds - How long to wait before taking screenshots.
--tempdir=/path/to/temp/location/ - Where to make 'temporary' files.
--noupload - Do not upload to TheP(aste)B.in

Other:
--get-max-size - Get the maximum file size from TheP(aste)B.in
--version - Display version.

Examples:
upload --img=/path/to/nakedlady.png --nsfw
upload --video=/path/to/awesomeness.avi
upload --video=/path/to/that_one_awesome-video.mp4 --frames=3
upload --video=/path/to/that_one_awesome-video.mp4 --save=1 --tempdir=$HOME/Desktop/
upload --img=/path/to/thisone.png --img=/path/to/that/other/one.png
upload -f -f -f --delay=6 --sfw
upload -f -a -a --img=/path/to/this/one/nude.png --delay=4 --nsfw
