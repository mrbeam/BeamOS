git clone https://github.com/mrbeam/MrBeamPlugin.git
mrbeam_ledstrips
netconnectcli status
tail -f -n200 /var/log/netconnectd.log
tail -f -n200 ~/.octoprint/logs/octoprint.log
sudo systemctl restart octoprint.service
sudo systemctl status octoprint.service
source ~/oprint/bin/activate
cd ~/oprint/lib/python2.7/site-packages/
cd ~/oprint/lib/python2.7/site-packages/octoprint_mrbeam/