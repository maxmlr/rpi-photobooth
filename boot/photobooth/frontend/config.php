<?php
require_once(__DIR__ . '/arrayDeepMerge.php');

$default_config_file = __DIR__ . '/../config/config.inc.php';
$my_config_file = __DIR__ . '/../config/my.config.inc.php';
$os = (DIRECTORY_SEPARATOR == '\\') || (strtolower(substr(PHP_OS, 0, 3)) === 'win') ? 'windows' : 'linux';

$cmds = [
    'windows' => [
        'take_picture' => [
            'cmd' => 'digicamcontrol\CameraControlCmd.exe /capture /filename %s',
            'msg' => 'Photo transfer done.'
        ],
        'print' => [
            'cmd' => 'mspaint /pt "%s"',
            'msg' => '',
        ]
    ],
    'linux' => [
        'take_picture' => [
            'cmd' => 'gphoto2 --capture-image-and-download --filename=%s',
            'msg' => 'New file is in location'
        ],
        'print' => [
            'cmd' => 'lp -o landscape -o fit-to-page %s',
            'msg' => '',
        ]
    ],
];

$mailTemplates = [
    'de' => [
        'mail_subject' => 'Hier ist dein Bild',
        'mail_text' => 'Hey, dein Bild ist angehangen.',
    ],
    'en' => [
        'mail_subject' => 'Here is your picture',
        'mail_text' => 'Hey, your picture is attached.',
    ],
    'es' => [
        'mail_subject' => 'Aquí está tu foto',
        'mail_text' => 'Hola, tu foto está adjunta.',
    ],
    'fr' => [
        'mail_subject' => 'Voici votre photo',
        'mail_text' => 'Hé, ta photo est attachée.',
    ],
];

require_once($default_config_file);

$config['mail_subject'] = $mailTemplates[$config['language']]['mail_subject'];
$config['mail_text'] = $mailTemplates[$config['language']]['mail_text'];
$config['take_picture']['cmd'] = $cmds[$os]['take_picture']['cmd'];
$config['take_picture']['msg'] = $cmds[$os]['take_picture']['msg'];
$config['print']['cmd'] = $cmds[$os]['print']['cmd'];
$config['print']['msg'] = $cmds[$os]['print']['msg'];

$config['collage_limit'] = 3;

$defaultConfig = $config;

if (file_exists($my_config_file)) {
    require_once($my_config_file);

    $config = array_deep_merge($defaultConfig, $config);
}

if ($config['dev']) {
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1);
    error_reporting(E_ALL);
}

if (!isset($config['background_image'])) {
    $config['background_image'] = 'url(../img/bg.jpg)';
}

if (!isset($config['background_admin'])) {
    $config['background_admin'] = 'url(../img/bg.jpg)';
}

if (!isset($config['background_chroma'])) {
    $config['background_chroma'] = 'url(../img/bg.jpg)';
}

if (file_exists($my_config_file) && !is_writable($my_config_file)) {
    die('Abort. Can not write config/my.config.inc.php.');
} elseif (!file_exists($my_config_file) && !is_writable(__DIR__ . '/../config/')) {
    die('Abort. Can not create config/my.config.inc.php. Config folder is not writable.');
}

foreach ($config['folders'] as $key => $folder) {
    $path = __DIR__ . DIRECTORY_SEPARATOR . '..' . DIRECTORY_SEPARATOR . $folder;

    if (!file_exists($path)) {
        if (!mkdir($path, 0755, true)) {
            die("Abort. Could not create $folder.");
        }
    } elseif (!is_writable($path)) {
        die("Abort. The folder $folder is not writable.");
    }

    $path = realpath($path);
    $config['foldersAbs'][$key] = $path;
}
