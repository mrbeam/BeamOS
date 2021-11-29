BeamOS
======

.. image:: https://raw.githubusercontent.com/mrbeam/BeamOS/mrbeam/media/BeamOS.png
.. :scale: 50 %
.. :alt: Mr Beam logo

A `Raspberry Pi <http://www.raspberrypi.org/>`_ distribution for the Mr Beam Laser Cutters. It includes the `OctoPrint <http://octoprint.org>`_ host software for 3d printers out of the box and the MrBeamPlugin that extends OctoPrint to be used with the Mr Beam Laser Cutters.

This repository contains the source script to generate the distribution out of an existing `Raspbian <http://www.raspbian.org/>`_ distro image.

This repository is a fork of `OctoPi <https://github.com/guysoft/OctoPi>`_ but is not maintained by or affiliated with the maintainers of that project. This is a project integral to the laser cutters produced by MrBeam and cannot be used for a 3D printer out of the box.

TODO:  Add possibility to switch between tags, branches and python versions.

How to use it?
--------------

#. Unzip the image and install it to an sd card `like any other Raspberry Pi image <https://www.raspberrypi.org/documentation/installation/installing-images/README.md>`_
#. Configure your WiFi by editing ``octopi-wpa-supplicant.txt`` on the root of the flashed card when using it like a thumb drive
#. Boot the Pi from the card
#. Access the MrBeam using it's name ``MrBeam-XXXX`` at the back of the device, the address should be `mrbeam-xxxx.local`. This name is generated using the RaspberryPi serial number

Features
--------

* `OctoPrint <http://octoprint.org>`_ host software for 3d printers
* `MrBeam Plugin for OctoPrint <https://mr-beam.org>`_ Modifies host software to work on the MrBeam lasecutter specifically
* `Raspbian <http://www.raspbian.org/>`_ tweaked for maximum performance for printing out of the box
* `mjpg-streamer with RaspiCam support <https://github.com/jacksonliam/mjpg-streamer>`_ for live viewing of prints and timelapse video creation.

Requirements
~~~~~~~~~~~~

#. `qemu-arm-static <http://packages.debian.org/sid/qemu-user-static>`__ If not running on an RPi
#. `CustomPiOS <https://github.com/guysoft/CustomPiOS>`_
#. Downloaded `Raspbian <http://www.raspbian.org/>`_ image.
#. root privileges for chroot
#. Bash
#. git
#. sudo (the script itself calls it, running as root without sudo won't work)

Build BeamOS From within BeamOS / Raspbian / Debian / Ubuntu
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

BeamOS can be built from Debian, Ubuntu, Raspbian, or even BeamOS.
Build requires about 2.5 GB of free space available.
It is recommended to use a fast storage as the script decompresses the .zip file of raspbian every time.

You can build it by issuing the following commands::

    sudo apt-get install gawk util-linux qemu-user-static git p7zip-full python3
    
    git clone https://github.com/guysoft/CustomPiOS.git
    git clone https://github.com/mrbeam/BeamOS.git
    cd BeamOS/src/image
    wget -c --trust-server-names 'https://downloads.raspberrypi.org/raspios_lite_armhf_latest'
    cd ..
    ../../CustomPiOS/src/update-custompios-paths
    sudo modprobe loop
    sudo bash -x ./build_dist beamos
    
Building BeamOS Variants
~~~~~~~~~~~~~~~~~~~~~~~~

BeamOS supports building variants, which are builds with changes from the main release build. An example and other variants are available in `CustomPiOS, folder src/variants/example <https://github.com/guysoft/CustomPiOS/tree/CustomPiOS/src/variants/example>`_.

By default it only builds a slightly different version of vanilla OctoPi. Give it the ``beamos`` variant to build the normal BeamOS.

docker exec -it mydistro_builder::

    sudo docker exec -it mydistro_builder build [Variant]

Or to build a variant inside a container::

    sudo bash -x ./build_dist [Variant]

Building BeamOS Flavors
~~~~~~~~~~~~~~~~~~~~~~~

Flavors are simply extra config tweaking on the base variant. I the case of BeamOS, it allows to build a ``develop`` flavor and/or a pre-filled device series for the MrBeam (2S, 2T, 2U ...) ::

    sudo bash -x ./build_dist beamos [Flavor]

Or to make a develop image that automatically takes on the 2S variant::

    sudo bash -x ./build_dist beamos develop 2S

Building Using Docker
~~~~~~~~~~~~~~~~~~~~~~
`See Building with docker entry in wiki <https://github.com/guysoft/CustomPiOS/wiki/Building-with-Docker>`_

Usage
~~~~~

#. If needed, override existing config settings by creating a new file ``src/config.local``. You can override all settings found in ``src/modules/beamos/config``. If you need to override the path to the Raspbian image to use for building BeamOS, override the path to be used in ``ZIP_IMG``. By default the most recent file matching ``*-raspbian.zip`` found in ``src/image`` will be used.
#. Run ``src/build_dist`` as root.
#. The final image will be created at the ``src/workspace``

Development
-----------

All the scripts are written in Bash - not POSIX.

How it works
~~~~~~~~~~~~

The collections of scripts work with a set of "modules". When no modules are provided, the script only creates an updated Raspbian image with limited changes (username, hostname, network setup ...). For more info around the modules, have a look at the `Modules wiki for CustomPiOS <https://github.com/guysoft/CustomPiOS/wiki/Modules>`_

The scripts will do the following (abridged):

#. unzip the raspbian image from the provided .zip in ``src/image/`` or ``src/image-raspios_lite_arm64/`` into the ``image/`` folder and mount it
#. for each module:
   #. ``cd modules/<module>/``
   #. Collect and ``export`` the configuration variables from the ``config``, ``config.local`` and ``config.flavour``
   #. Mount the ``filesystem/`` folder on root ``/``
   #. Change root (`chroot <https://wiki.archlinux.org/title/Chroot>`_) to the mounted image.
   #. Run the ``start_chroot_script`` shell/bash script
   #. Optionaly run a nested module here (will unmount the ``filesystem`` and exit/reenter chroot in the process)
   #. Run the ``stop_chroot_script`` shell/bash script
   #. exit chroot
#. The end result image is in ``image/`` folder, ready to be ``dd``'ed onto an SD card.

Secrets
~~~~~~~

This repository is public, but it uses GitHub secrets to pull from proprietary sources and include authentication keys. 
You can find the GitHub secrets in the `project settings <https://github.com/mrbeam/BeamOS/settings/secrets/actions>`_

.. _submodules:

Private repos included in BeamOS 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Because of complications when using `actions/checkout <https://github.com/actions/checkout>`_, the proprietary projects 
have been added to the beamos module filesystem as git submodules. Their commit hash needs to be updated as part of this git repo::

    git submodule sync
    git foreach "git pull"
    git add src/modules/beamos/filesystem/repos
    git commit -m "Update X Y Z package"

These repos are

* `IOBeam <https://github.com/mrbeam/iobeam>`_  handles most IO components
    * branch: ``mrbeam2-stable``
* `Mount Manager <https://github.com/mrbeam/mount_manager>`_ to run signed scripts when plugging in a usb stick
    * branch: ``mrbeam2-stable``
* `MrB Check <https://github.com/mrbeam/mrb_check>`_ Automated QA control script for the assembly of the MrBeam
    * branch: ``beamos``
* `MrB Hardware Info <https://github.com/mrbeam/>`_ Provides additional readings for IOBeam
    * branch: ``mrbeam2-stable``

N.B. These repos are NOT affected by the branch written in the config files for building BeamOS.

Public MrBeam projects included in BeamOS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

All the open source repos are pulled using a specific branch, no need to make an update to this repository.

* `MrBeamPlugin <https://github.com/mrbeam/MrBeamPlugin>`_ The main plugin that drives the lasercutter
    * branch : ``mrbeam2-stable``
* `Netconnectd <https://github.com/mrbeam/netconnectd_mrbeam>`_ The networking server that handles wifi and access point modes
    * branch : ``master``
* `OctoPrint-Netconnectd <https://github.com/mrbeam/octoprint_netconnectd>`_ The OctoPrint plugin that interfaces with Netconnectd
    * branch : ``mrbeam2-stable``
* `OctoPrint-Camera <https://github.com/mrbeam/OctoPrint-Camera>`_ A camera plugin used for the QA testing (as of writing this)
    * branch : ``master``
* `LED strips server <https://github.com/mrbeam/MrBeamLedStrips>`_ state-based LED strip driver
* `Find My MrBeam <https://github.com/mrbeam/OctoPrint-FindMyMrBeam>`_ OctoPrint plugin that sends network discovery data
* `Shield flash tool <https://github.com/mrbeam/shield_flasher>`_ updates the microcontroller with our latest GRBL version
* `RPI_WS281X <https://github.com/mrbeam/rpi_ws281x>`_ (discontinued) an LED strip driver used with the LED server
    * Uses the latest Python3 package from `the upstream RPI_WS281X <https://github.com/rpi-ws281x/rpi-ws281x-python>`_
* `MrBeam Docs <https://github.com/mrbeam/MrBeamDoc>`_ The documentation for using your MrBeam - offline

N.B. The listed branches can change with the "flavours" that you decide to build. For example, you could build a beta or alpha flavour that includes the mrbeam2-beta branches from the public repos. Private repos need to be changed and committed manually.


Automated Deployment
~~~~~~~~~~~~~~~~~~~~

Every push to this repo will trigger a `GitHub Action <https://github.com/mrbeam/BeamOS/actions>`_. 

2 images will be built:

* Stable version ``YYYY-MM-DD-beamos-2S.img`` - it should be used when assembling new devices of the ``2S`` variant
* Develop version ``YYYY-MM-DD-beamos-develop-2S.img`` - Predefined develop account, options and settings;
  should be just "plug-n-play" except for the camera calibration

These images are compressed and uploaded to an S3 storage defined in ``build.yml`` and the base64 encoded credentials are provided as a secret. See internal documentation to access these builds.

Alpha Image Release
~~~~~~~~~~~~~~~~~~~

If you have access to the project, you can trigger a build for an alpha version image in the GitHub Actions using ``Build image`` > ``Run workflow`` > ``Alpha build true/false default: false`` : ``true``


Making a new release
~~~~~~~~~~~~~~~~~~~~

#. Update the private submodules_
#. If a submodule was updated, be sure to commit the commit hash change.
#. Once pushed, a new build will run with a `Github automation <https://github.com/mrbeam/BeamOS/actions>`_
#. After testing the result of the uploaded image, `create a new release <https://github.com/mrbeam/BeamOS/releases/new>`_
#. Be sure to attach the ``.zip`` file to publish the image with the release.
