mrbeam_ledstrips_cli flash_white
mrbeam_ledstrips_cli
netconnectcli status
tail -f -n200 /var/log/mount_manager.log
tail -f -n200 /var/log/netconnectd.log
tail -f -n200 /var/log/mrbeam_ledstrips.log
tail -f -n200 /var/log/iobeam.log
tail -f -n200 /var/log/mrb_check.log
tail -f -n200 ~/.octoprint/logs/octoprint.log
source ~/oprint/bin/activate
sudo systemctl restart netconnectd.service
sudo systemctl restart mrbeam_ledstrips.service
sudo systemctl restart iobeam.service
sudo systemctl restart octoprint.service
sudo systemctl status octoprint.service
restart_octoprint
restart_iobeam
restart_mrbeam_ledstrips
restart_netconnectd
cd /usr/local/lib/python2.7/dist-packages/
cd ~/oprint/lib/python2.7/site-packages/
cd ~/oprint/lib/python2.7/site-packages/octoprint_mrbeam/
iobeam_debug
iobeam_info fan:off
iobeam_info
cat /etc/mrbeam
cat ~/.octoprint/config.yaml