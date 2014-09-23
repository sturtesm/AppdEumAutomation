#!/bin/sh

DOC_ROOT=/Library/WebServer/Documents
TOP_LEVEL=`dirname $0`

sudo cp ${TOP_LEVEL}/php-spider.php ${DOC_ROOT}
