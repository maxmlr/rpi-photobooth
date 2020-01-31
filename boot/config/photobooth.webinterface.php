<?php
$config = array (
  'show_fork' => false,
  'previewFromCam' => true,
  'previewCamTakesPic' => false,
  'background_image' => 'url(../img/bg.jpg)',
  'background_admin' => 'url(../img/bg.jpg)',
  'background_chroma' => 'url(../img/bg.jpg)',
  'webserver_ip' => 'photobooth',
  'rounded_corners' => true,
  'photo_key' => '32',
  'collage_key' => '67',
  'start_screen_subtitle' => 'By Max and Max',
  'take_picture' =>
  array (
    //cmd' => 'raspistill -n -o %s -q 100 -t 1 | echo Done',
    'cmd' => 'gphoto2 --capture-image-and-download --filename=%s',
    //'msg' => 'Done',
    'msg' => 'New file is in location',
  ),
);
