@echo off

REM remove ^M ( Ctrl + M ) from the end of line
dos2unix 2018022301_netgear/update.sh
tar czf 2018022301_netgear.tar.gz ./2018022301_netgear
scp 2018022301_netgear.tar.gz hexcola@ianki.cn:/home/hexcola/cellhub/public
del czf 2018022301_netgear.tar.gz

dos2unix 2018022301_xiaomi/update.sh
tar czf 2018022301_xiaomi.tar.gz ./2018022301_xiaomi
scp 2018022301_xiaomi.tar.gz hexcola@ianki.cn:/home/hexcola/cellhub/public
del czf 2018022301_xiaomi.tar.gz