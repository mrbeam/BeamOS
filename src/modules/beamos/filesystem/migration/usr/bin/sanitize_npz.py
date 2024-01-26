#!/usr/bin/python3
""" Module to santitize npz files to be compatible with python 3.x """
import os
import shutil
import numpy as np


PRESERVE_DATA_CAM_DIRECTORY="/mrbeam/preserve-data/home/pi/.octoprint/cam/"

BUSTER_FACTORY_LENS_CALIBRATION="factory_lens_correction.npz"
LEGACY_FACTORY_LENS_CALIBRATION="lens_correction_2048x1536.npz"
USER_LENS_CALIBRATION="lens_correction.npz"

LENS_CALIBRATTION_FILES=[
    BUSTER_FACTORY_LENS_CALIBRATION, LEGACY_FACTORY_LENS_CALIBRATION, USER_LENS_CALIBRATION]


def sanitize_npz(npz_file: str) -> None:
    """Sanitize npz files to be compatible with python 3.x.

    Args:
        * npz_file (str) : path to the npz file to be sanitized

    Returns:
        * None

    Raises:
        * np.lib.format.FormatError: if the file is not a valid npz file
    """
    print("Sanitizing: " + npz_file)
    try:
        data = np.load(npz_file, encoding='latin1', allow_pickle=True)
    except np.lib.format.FormatError as _e:
        print("Error loading file: " + str(_e))
    np.savez_compressed(npz_file, **data)


def sanitize_npz_files() -> None:
    """Sanitize all npz files in the cam directory"""
    for _f in LENS_CALIBRATTION_FILES:
        npz_file = os.path.join(PRESERVE_DATA_CAM_DIRECTORY, _f)
        if os.path.isfile(npz_file):
            # create backup retain the original file
            shutil.copy2(npz_file, npz_file+".original")
            sanitize_npz(npz_file)
        else:
            print("File not found: " + npz_file)


if __name__ == "__main__":
    sanitize_npz_files()
