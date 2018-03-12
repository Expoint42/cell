@echo off

REM remove ^M ( Ctrl + M ) from the end of line
dos2unix cell/auto/*
dos2unix cell/config/*
dos2unix cell/scripts/*
dos2unix cell/tools/*
dos2unix cell/upgrade/*
dos2unix cell/upgrade/2018022301/*
dos2unix cell/install.sh
dos2unix cell/package
dos2unix cell/setup.sh
dos2unix cell/update.sh

tar czf cell.tar.gz ./cell
scp cell.tar.gz hexcola@ianki.cn:/home/hexcola/cellhub/public
del czf cell.tar.gz