<?php
$config = array (
  'show_fork' => false,
  'previewFromCam' => true,
  'previewCamTakesPic' => false,
  'background_image' => 'url(../resources/img/bg.jpg)',
  'background_admin' => 'url(../resources/img/bg.jpg)',
  'background_chroma' => 'url(../resources/img/bg.jpg)',
  'print_frame' => false,
  'print_frame_path' => '../resources/img/frames/frame.png',
  'take_frame' => false,
  'take_frame_path' => '../resources/img/frames/frame.png',
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
