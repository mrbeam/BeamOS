# TODO list

## Bugs

- Find.mrbeam not working (Does not receive ipv6 address) (Andy+Axel)
  ```
  octoprint.plugins.findmymrbeam INFO FindMyMrBeam 
    registration: OK - 
    ip4_status: 200, 
    public_ip: xxx.xxx.xxx.xxx, (masked for privacy) 
    ip6_status: requests.ConnectionError, 
    public_ip6: None, 
    hostname: MrBeam-86F4, 
    local_ips: 10.42.0.237, 
    netconnectd_state: {'ap': False, 'wifi': False, 'wired': True}, 
    internal_modes: []
  ```
- Analytics handler broken (Khaled: solved but after merging develop, it's not showing anymore so solution wasn't committed)
  ```
  15:17:38 octoprint.plugins.mrbeam.migrate ERROR Not able to get analytics_handler.
  ```
- Fix pip path for the specific packages (Axel)
  ```
  mrbeam.util.pip_util.get_version_of_pip_module ERROR `pip --disable-pip-version-check` was not found in local $PATH 
  ```
  > Some packages still don't have the correct link to the archive (all the private repos)

## Task List

### Requirement

- [ ] USB stick compat
  - [ ] mrb check -> Auto run ? (Basti)
  - [ ] update

- [ ] Merge the BeamOS specific branches for these packages
  - [ ] MrBeamPlugin
  - [~] mrbeam_ledstrips (client and server) (ready to merge)
  - [x] netconnectd
  - [x] netconnectd plugin
  - [x] [wifi](https://github.com/ManuelMcLure/wifi)
  - [~] iobeam (ready to merge)
- [ ] Test scenarios
  - [ ] New vs Old image
  - [ ] GRBL flash
  - [ ] Test legacy image compatibility
    - [ ] packages on legacy OS
    - [ ] legacy RPi
    - [ ] Test with mrb check / update sticks.
    - [ ] Sticks : update, reset {user/network/all}
  - [ ] Calibration tool
  - [ ] mount manager
  - [ ] iobeam
  - [ ] Software update (permissions etc...)
  - [ ] LEDstrips
  - [ ] Netconnectd
- [ ] Minimise image size & speed up image creation
  - [ ] Self compiled wheels & host/deploy wheels online
    - [ ] OpenCV (Or migrate to python3 & install headless py3 wheel (available on Pypi))
    - [ ] numpy (mostly for speed)
  - [ ] Remove numpy dependency for iobeam

### Nice to have

- fix `setup.py` scripts to include all relevant dependencies
  - MrBeamPlugin
  - iobeam (numpy - should probs be removed, mrb_hw_info)
  - mrb_hw_info (requests)
  - mrbeam_ledstrips (rpi_ws281x)
- Migrate or mirror projects to GitHub
  - iobeam
  - mrb_hw_info
  - mount_manager

## Stretch Goals

- Minimise priviledged user escalation (fewer sudo calls)
  - iobeam can run unprivileged
  - hostname can be set in very specific situations
  - Update tool daemon + Update tool client plugin
    - Fetch remote recipees
    - User accepts the updates
  - Remove password-less sudo (The PROD image version does that)
  
  
