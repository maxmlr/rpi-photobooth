<?php
$config = array (
  'show_fork' => false,
  'previewFromCam' => true,
  'previewCamTakesPic' => false,
  'background_image' => 'url(../img/bg.jpg)',
  'background_admin' => 'url(../img/bg.jpg)',
  'background_chroma' => 'url(../img/bg.jpg)',
  'print_frame' => false,
  'print_frame_path' => '../resources/img/frames/frame.png',
  'take_frame' => false,
  'take_frame_path' => '../resources/img/frames/frame.png',
  'webserver_ip' => 'photobooth',
  'rounded_corners' => true,
  'photo_key' => '32',
  'collage_key' => '67',
  'start_screen_subtitle' => 'By Max and Max',
  'login_enabled' => true,
  'login_username' => trim(explode('=', reset(preg_grep('/ADMIN_EMAIL/', file('/boot/photobooth.conf'))))[1]),
  'login_password' => password_hash(trim(explode('=', reset(preg_grep('/ADMIN_PASSWORD/', file('/boot/photobooth.conf'))))[1]), PASSWORD_DEFAULT),
  'take_picture' =>
  array (
    'cmd' => 'gphoto2 --capture-image-and-download --filename=%s',
    'msg' => 'New file is in location',
  ),
);
