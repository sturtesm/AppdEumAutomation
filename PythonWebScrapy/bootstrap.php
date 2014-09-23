<?php
require 'vendor/autoload.php';

// create object
$smarty = new Smarty;

$smarty->assign('title', 'Hello, World!');

// display it
$smarty->display('bootstrap.tpl');

?>
