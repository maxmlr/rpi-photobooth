<?php

function createCollage($srcImagePaths, $destImagePath, $takeFrame, $framePath, $imgCount = 3) {
    if (!is_array($srcImagePaths) || count($srcImagePaths) !== $imgCount) {
        return false;
    }

    list($width, $height) = getimagesize($srcImagePaths[0]);

    $my_collage = imagecreatetruecolor($width, $height);
    $background = imagecolorallocate($my_collage, 0, 0, 0);
    imagecolortransparent($my_collage, $background);

    $positions = [
        [0, 0],
        [(1*$width) / 3, 0],
        [(2*$width) / 3, 0],
        
        [0, $height / 2],
        [(1*$width) / 3, $height / 2],
        [(2*$width) / 3, $height / 2]
    ];

    for ($i = 0; $i < $imgCount; $i++) {
        $position = $positions[$i];
        $position2 = $positions[$i+$imgCount];

        if (!file_exists($srcImagePaths[$i])) {
            return false;
        }

        $tempSubImage = imagecreatefromjpeg($srcImagePaths[$i]);

        $tempSubImageR = imagerotate($tempSubImage, 90, 0);
        imagecopyresized($my_collage, $tempSubImageR, $position[0] + $width * 0.009375, $position[1] + $height * 0.0125, 0, $height / 4, $width * 0.475, $height * 0.475, $width, $height);
        imagecopyresized($my_collage, $tempSubImageR, $position2[0] + $width * 0.009375, $position2[1] + $height * 0.0125, 0, $height / 4, $width * 0.475, $height * 0.475, $width, $height);
        imagedestroy($tempSubImage);
        imagedestroy($tempSubImageR);
    }

    if ($takeFrame) {
        $frame = imagecreatefrompng($framePath);
        $frame = resizePngImage($frame, imagesx($my_collage), imagesy($my_collage));
        $x = (imagesx($my_collage)/2) - (imagesx($frame)/2);
        $y = (imagesy($my_collage)/2) - (imagesy($frame)/2);
        imagecopy($my_collage, $frame, $x, $y, 0, 0, imagesx($frame), imagesy($frame));
    }


    imagejpeg($my_collage, $destImagePath);
    imagedestroy($my_collage);

    return true;
}