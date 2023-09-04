<?php

$inputFilePath = '1.rgb';

$inputFile = fopen($inputFilePath, 'rb');
$rgbData = fread($inputFile, filesize($inputFilePath));
fclose($inputFile);

$targetImage = imagecreatetruecolor(64, 64);//csgo avatar is always 64 x 64

$pixelPosition = 0;

for ($y = 0; $y < 64; $y++) 
{
    for ($x = 0; $x < 64; $x++) 
    {
        imagesetpixel($targetImage, $x, $y, imagecolorallocate($targetImage, ord($rgbData[$pixelPosition]), ord($rgbData[$pixelPosition + 1]), ord($rgbData[$pixelPosition + 2])));
        $pixelPosition += 3;
    }
}

$outputFilePath = 'output.png';
imagepng($targetImage, $outputFilePath);
imagedestroy($targetImage);

?>
