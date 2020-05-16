<?php

include './create-thumbnail.php';

class FileAPI {
    public function getDir($type) {
        if ($type == "background") {
            return "../files/backgrounds";
        }
        else if ($type == "frame") {
            return "../files/frames";
        }
        return NULL;
    }

    public function getTarget($type) {
        if ($type == "background") {
            return "selected_background_" . date("Ymd_h-i-s");
        }
        else if ($type == "frame") {
            return "selected_frame_" . date("Ymd_h-i-s");
        }
        return NULL;
    }

    public static function get($type) {
        $DIR = self::getDir($type);
        if (is_null($DIR)) {
            return [];
        }
        
        $imageOnly = 'thumb_*.{[jJ][pP][gG],[jJ][pP][eE][gG],[pP][nN][gG],[gG][iI][fF]}';
        chdir($DIR);
        $res = glob($imageOnly, GLOB_BRACE);
        return $res;
    }

    public static function delete($type, $fname) {
        $DIR = self::getDir($type);
        if (is_null($DIR)) {
            return [];
        }

        $fname = substr($fname, 6);
        $ds = DIRECTORY_SEPARATOR;
        $targetFile =  $DIR . $ds . $fname;
        $targetFile_thumb =  $DIR . $ds . 'thumb_' . $fname;
        unlink($targetFile);
        unlink($targetFile_thumb);
        return "deleted";
    }

    public static function store($type, $files) {
        $DIR = self::getDir($type);
        if (is_null($DIR)) {
            return [];
        }

        $ds = DIRECTORY_SEPARATOR;
        if (!empty($files)) {
            $tempFile = $_FILES['file']['tmp_name'];
            $targetFile =  $DIR . $ds . $_FILES['file']['name'];
            $targetFile_thumb =  $DIR . $ds . 'thumb_' . $_FILES['file']['name'];
            if (file_exists($targetFile)) {
                return "exists";
            } else {
                move_uploaded_file($tempFile, $targetFile);
                createThumbnail($targetFile, $targetFile_thumb, 350);
                return 'thumb_' . $_FILES['file']['name'];
            }
        }
        return "no-file";
    }

    public static function select($type, $fname) {
        $DIR = self::getDir($type);
        if (is_null($DIR)) {
            return [];
        }

        $fname = substr($fname, 6);
        $target = self::getTarget($type);
        $targetBase = "../files";
        $ds = DIRECTORY_SEPARATOR;
        $selectedFile =  $DIR . $ds . $fname;
        $ext = pathinfo($fname, PATHINFO_EXTENSION);
        $targetFile = $targetBase . $ds . $target . '.' . $ext;
        $targetFileTmp = $targetBase . $ds . '.' . $target . '.' . $ext;
        
        createThumbnail($selectedFile, $targetFileTmp, 1920);
        // if (!copy($selectedFile, $targetFileTmp)) {
        if (!file_exists($targetFileTmp)) {
            return "copy-failed";
        } else {
            if ($type == "background") {
                shell_exec('./edit_photobooth_conf.sh background_image ' . $target . '.' . $ext . ' ' . $type);
            }
            else if ($type == "frame") {
                shell_exec('./edit_photobooth_conf.sh print_frame_path ' . $target . '.' . $ext . ' ' . $type);
                shell_exec('./edit_photobooth_conf.sh take_frame_path ' . $target . '.' . $ext . ' ' . $type);
            }
            rename($targetFileTmp, $targetFile);
        }
        return "copied";
    }
}