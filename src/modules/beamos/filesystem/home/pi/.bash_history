mrbeam_ledstrips_cli flash_white
mrbeam_ledstrips_cli
i2cset 0x2a 0x81 0x64 # Exhaust 100%
i2cset 0x2a 0x81 0x00 # Exhaust off
i2cset 0x2c 0x82 0x64 # Compressor 200 mbar
i2cset 0x2c 0x82 0x00 # Compressor off
i2cset 0x2c 0x87 0x64 # Ozon	100 PPM
i2cset 0x2c 0x87 0x00 # Ozon off
i2cdetect
netconnectcli status
tail -f -n200 /var/log/mount_manager.log
tail -f -n200 /var/log/netconnectd.log
tail -f -n200 /var/log/mrbeam_ledstrips.log
tail -f -n200 /var/log/iobeam.log
tail -f -n200 /var/log/mrb_check.log
tail -f -n200 ~/.octoprint/logs/octoprint.log
workon oprint
sudo shutdown now
sudo reboot
systemctl restart netconnectd # pi user has permission to use systemd
systemctl restart mrbeam_ledstrips # pi user has permission to use systemd
systemctl restart iobeam # pi user has permission to use systemd
systemctl restart octoprint # pi user has permission to use systemd
systemctl status octoprint # pi user has permission to use systemd
restart_iobeam
restart_mrbeam_ledstrips
restart_netconnectd
restart_octoprint
iobeamcli info
iobeamcli fan -c off
iobeamcli fan -c on 100
iobeamcli
sudo nano /etc/mrbeam # uses micro, use Ctrl + q to quit, Ctrl + g for shortcut list
sudo nano ~/.octoprint/config.yaml # uses micro, use Ctrl + q to quit, Ctrl + g for shortcut list
nano /etc/mrbeam # uses micro, use Ctrl + q to quit, Ctrl + g for shortcut list
nano ~/.octoprint/config.yaml # uses micro, use Ctrl + q to quit, Ctrl + g for shortcut list
yq e ~/.octoprint/config.yaml # inspect config.yaml
