<?
    $font = "YS.ttf";
    $fontSize = 17;
    $buffer = $_GET["id"];
    $qq_ava = $_GET["qq"];
    $height = 64;
    $width = 300;
    if(!array_key_exists("id", $_GET))
    {
        echo "没有传入id参数";
        exit();
    }
    if(array_key_exists("width", $_GET))
    {
        $width = $_GET["width"] > 300?$_GET["width"]:300;
    }
    $image = imagecreatetruecolor($width, $height);
    imagecolortransparent($image, imagecolorallocatealpha($image, 255, 255, 255, 127));
    imagesavealpha($image, true);
    imagefill($image, 0, 0, imagecolorallocatealpha($image, 255, 255, 255, 127));
    if(array_key_exists("color", $_GET))
    {
        $fontcolor = hexToRgb($_GET["color"]);
        $text_color = imagecolorallocate($image, $fontcolor['r'], $fontcolor['g'], $fontcolor['b']);
    }
    else
        $text_color = imagecolorallocate($image, 255, 255, 255);
    
    $fontBox = imagettfbbox($fontSize, 0, $font, $buffer);
    $x = ceil(($width - $fontBox[2]) / 2);
    $y = ceil(($height - 50) / 2) - 5;
    imagettftext($image, $fontSize, 0, $x, 38, $text_color, $font, $buffer);
    //imagettftext($image, $fontSize, 0, $x - 52, 38, $text_color, $touhoufont, "&#xF030;"); GD库不支持4个字符长度的符号,so we use png. lol
    if($qq_ava != null)
    {
        $qq_ava = resize(imagecreatefromjpeg("https://q1.qlogo.cn/g?b=qq&nk=$qq_ava&s=640"));
        imagecopymerge($image, $qq_ava, $x - 52, $y + 3, 0, 0, 50, 50, 100);
    }
    header('Content-Type: image/png');
    imagepng($image);
    imagedestroy($image);
    
    function resize($img, $newx = 50,$newy = 50)
    {
        $x = imagesx($img);
        $y = imagesy($img);
        $im2 = imagecreatetruecolor($newx, $newy);
        $color = imagecolorallocate($im2, 255, 255, 255);
        imagecolortransparent($im2, $color); 
        imagefill($im2, 0 , 0, $color);
        imagecopyresized($im2, $img, 0, 0, 0, 0, $newx, $newy, $x, $y);
        return $im2;
    }
    
    function hexToRgb($hex, $alpha = false) 
    {
       $hex      = str_replace('#', '', $hex);
       $length   = strlen($hex);
       $rgb['r'] = hexdec($length == 6 ? substr($hex, 0, 2) : ($length == 3 ? str_repeat(substr($hex, 0, 1), 2) : 0));
       $rgb['g'] = hexdec($length == 6 ? substr($hex, 2, 2) : ($length == 3 ? str_repeat(substr($hex, 1, 1), 2) : 0));
       $rgb['b'] = hexdec($length == 6 ? substr($hex, 4, 2) : ($length == 3 ? str_repeat(substr($hex, 2, 1), 2) : 0));
       if ( $alpha ) {
          $rgb['a'] = $alpha;
       }
       return $rgb;
    }
?>