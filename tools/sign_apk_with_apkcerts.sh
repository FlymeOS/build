#!/bin/bash

SIGN_JAR=$PORT_ROOT/build/tools/signapk.jar
JAVA_LIBRARY_PATH=$PORT_ROOT/build/tools/lib64

apkName=$1
apkCertsTxt=$2
apkIn=$3
apkOut=$4

eval $(awk -F\" '{if ($2 == "'$apkName'") {print $0}}' $apkCertsTxt)
if [ "$certificate" == "PRESIGNED" ]; then
    echo "PRESIGNED"
    cp $apkIn $apkOut
elif [ "x$certificate" != "x" ] && [ "x$private_key" != "x" ]; then
    echo $certificate
    echo $private_key
    cp $apkIn $apkIn.unsigned
    zip -d $apkIn.unsigned "META-INF/*" 2>&1 > /dev/null
    java -Djava.library.path=$JAVA_LIBRARY_PATH -jar $SIGN_JAR $PORT_ROOT/$certificate $PORT_ROOT/$private_key $apkIn.unsigned $apkOut;
    rm $apkIn.unsigned
else
    echo "WARNNING: No Signature found in $apkCertsTxt, using PRESIGNED."
    echo "          Check the signature of $apkName if bugs occurs related to SeAndroid."
    cp $apkIn $apkOut
fi

