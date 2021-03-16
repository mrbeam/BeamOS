# TODO list

## Bugs

- Slicing : Only empty gcode files are created
- Find.mrbeam not working (Does not receive ipv6 address)
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
- Laser safety notice : cannot send to server (Err 901)
  ```
  tornado.access ERROR 901 POST /api/plugin/mrbeam (127.0.0.1) 2750.35ms
  ```
- Analytics handler broken
  ```
  15:17:38 octoprint.plugins.mrbeam.migrate ERROR Not able to get analytics_handler.
  ```
- Fix pip path for the specific packages
  ```
  mrbeam.util.pip_util.get_version_of_pip_module ERROR `pip --disable-pip-version-check` was not found in local $PATH 
  ```

## Task List

- Merge the BeamOS specific branches for these packages
  - MrBeamPlugin
  - mrbeam_ledstrips (client and server)
  - netconnectd
  - netconnectd plugin
  - [wifi](https://github.com/ManuelMcLure/wifi)
- Migrate or mirror projects to GitHub
  - iobeam
  - mrb_hw_info
  - mount_manager
- fix setup scripts to include all relevant dependencies
  - MrBeamPlugin
  - iobeam (numpy - should probs be removed, mrb_hw_info)
  - mrb_hw_info (requests)
  - mrbeam_ledstrips (rpi_ws281x)

## Stretch Goals

- Minimise priviledged user escalation (fewer sudo calls)
  - iobeam can run unprivileged
  - hostname can be set in very specific situations
  - Update tool daemon + Update tool client plugin
    - Fetch remote recipees
    - User accepts the updates
  - Remove password-less sudo (The PROD image version does that)
  
  
