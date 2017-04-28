git clone https://github.com/mrbeam/OctoPrint-Netconnectd.git
git clone https://github.com/mrbeam/OctoPrint-FindMyMrBeam.git
git clone git@bitbucket.org:mrbeam/iobeam.git
git clone https://github.com/mrbeam/MrBeamLedStrips.git
git clone https://github.com/mrbeam/MrBeamPlugin.git
mrbeam_ledstrips_cli progress:20
mrbeam_ledstrips_cli
netconnectcli status
tail -f -n200 /var/log/netconnectd.log
tail -f -n200 /var/log/mrbeam_ledstrips.log
tail -f -n200 /var/log/iobeam.log
tail -f -n200 ~/.octoprint/logs/octoprint.log
sudo systemctl restart netconnectd.service
sudo systemctl restart mrbeam_ledstrips.service
sudo systemctl restart iobeam.service
sudo systemctl restart octoprint.service
sudo systemctl status octoprint.service
source ~/oprint/bin/activate
cd /usr/local/lib/python2.7/dist-packages/
cd ~/oprint/lib/python2.7/site-packages/
cd ~/oprint/lib/python2.7/site-packages/octoprint_mrbeam/