# for cleaning stuff up to reset verison number and push to github
if [ -f Packages/org* ];
then
	rm -rf ./trybeforebuy/org*
	PACKAGE=$(ls -t Packages/org* | head -1)
	cp $PACKAGE ./trybeforebuy
fi
make clean
rm .theos/packages/*
rm .theos/last_package
echo "You're good to go! Just change the version number in your control file to whatever you want!"
exit 0
