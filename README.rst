BeamOS
======

.. image:: https://raw.githubusercontent.com/mrbeam/BeamOS/mrbeam/media/BeamOS.png
.. :scale: 50 %
.. :alt: Mr Beam logo

A `Raspberry Pi <http://www.raspberrypi.org/>`_ distribution for the Mr Beam Laser Cutters. It includes the `OctoPrint <http://octoprint.org>`_ host software for 3d printers out of the box and the MrBeamPlugin that extends OctoPrint to be used with the Mr Beam Laser Cutters.

This repository contains the source script to generate the distribution out of an existing `Raspbian <http://www.raspbian.org/>`_ distro image.

TODO
----

#. Add possibility to switch between tags, branches and python versions.

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

Developing
----------

# TODO

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
    sudo bash -x ./build_dist beamos [--ssh <.ssh>] [--gpg <.gnupg>]

 The ssh folder and gpg folder were omitted from the build script for security reasons. If you wish to add them, use the `--ssh` and `--gpg` flags.
    
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

Flavors are simply extra config tweaking on the base variant. I the case of BeamOS, it allows to build a ``develop`` flavor and/or a pre-filled device series for the MrBeam (2S, 2T, 2U ...) 

    sudo bash -x ./build_dist beamos [Flavor]

Or to make a develop image that automatically takes on the 2S variant:

    sudo bash -x ./build_dist beamos develop 2S

Building Using Docker
~~~~~~~~~~~~~~~~~~~~~~
`See Building with docker entry in wiki <https://github.com/guysoft/CustomPiOS/wiki/Building-with-Docker>`_

Usage
~~~~~

#. If needed, override existing config settings by creating a new file ``src/config.local``. You can override all settings found in ``src/modules/beamos/config``. If you need to override the path to the Raspbian image to use for building BeamOS, override the path to be used in ``ZIP_IMG``. By default the most recent file matching ``*-raspbian.zip`` found in ``src/image`` will be used.
#. Run ``src/build_dist`` as root.
#. The final image will be created at the ``src/workspace``

Code contribution would be appreciated!
