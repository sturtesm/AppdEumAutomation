<?php
require 'vendor/autoload.php';

// create object
$smarty = new Smarty;

// assign an array of data
$smarty->assign('urlSearchResults', array('bob','jim','joe','jerry','fred'));

// display it
$smarty->display('eum-search-results.tpl');
