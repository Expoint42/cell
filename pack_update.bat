@echo off

REM remove ^M ( Ctrl + M ) from the end of line
dos2unix 18030401/update.sh
tar czf 18030401.tar.gz ./18030401
scp 18030401.tar.gz hexcola@ianki.cn:/home/hexcola/cellhub/public
del czf 18030401.tar.gz
