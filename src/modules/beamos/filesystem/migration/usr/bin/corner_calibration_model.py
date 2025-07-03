#!/usr/bin/python3
"""Data model for the corner calibration."""
from dataclasses import dataclass
from enum import Enum
from typing import List, Optional
from packaging.version import Version

import os
import shutil
import sys
import yaml


LEGACY_FACT_RAW_CALIB_MARKERS_KEY = "factory_raw_calibMarkers"
LEGACY_FACT_RAW_CORNERS_FROM_IMAGE = "factory_raw_cornersFromImage"
LEGACY_USER_RAW_CALIB_MARKERS_KEY = "raw_calibMarkers"
LEGACY_USER_RAW_CORNERS_FROM_IMAGE = "raw_cornersFromImage"
LEGACY_CORNER_CALIBRATION_CORE_PLUGIN_VERSION = "2.1.0"


class CalibrationType(Enum):
    """Enum for the type of calibration."""

    USER = "user"
    FACTORY = "factory"


@dataclass
class CornerCalibrationModel:
    """A class to represent a corner calibration model."""

    top_left: List[int]
    top_right: List[int]
    bottom_left: List[int]
    bottom_right: List[int]
    type: CalibrationType
    width: float
    height: float

    @staticmethod
    def from_dict_legacy(
        data: dict,
        calibration_type: CalibrationType,
        width: float = 500.0,
        height: float = 390.0,
    ) -> Optional["CornerCalibrationModel"]:
        """Create a corner calibration model from a dictionary.

        Args:
            data: dictionary with the calibration data
            calibration_type: type of calibration
            width: width of the working area
            height: height of the working area

        Returns:
            A corner calibration model
        """
        try:
            return CornerCalibrationModel(
                top_left=data["NW"],
                top_right=data["NE"],
                bottom_left=data["SW"],
                bottom_right=data["SE"],
                type=calibration_type,
                width=float(width),
                height=float(height),
            )
        except KeyError:
            print(
                f"ERROR - Could not create corner calibration model from_dict_legacy: {data}"
            )
            return None

    @staticmethod
    def from_dict(
        data: dict,
    ) -> Optional["CornerCalibrationModel"]:
        """Create a corner calibration model from a dictionary.

        Args:
            data: dictionary with the calibration data

        Returns:
            A corner calibration model
        """
        try:
            calibration = data  # ["calibration"]
            return CornerCalibrationModel(
                top_left=calibration["top_left"],
                top_right=calibration["top_right"],
                bottom_left=calibration["bottom_left"],
                bottom_right=calibration["bottom_right"],
                type=CalibrationType(calibration["type"]),
                width=float(data["width"]),
                height=float(data["height"]),
            )
        except KeyError:
            print(
                f"ERROR - Could not create corner calibration model from_dict: {data}"
            )
            return None

    def to_dict(self):
        """Convert the corner calibration model to a dictionary.

        Returns:
            A dictionary with the corner calibration data
        """
        return {
            "top_left": self.top_left,
            "top_right": self.top_right,
            "bottom_left": self.bottom_left,
            "bottom_right": self.bottom_right,
            "type": self.type.value,
            "width": self.width,
            "height": self.height,
        }


class CornerCalibrationsModelException(Exception):
    """Exception for the corner calibrations model."""

    pass


class CornerCalibrationException(Exception):
    """Base exception for the CornerCalibrationHandler."""

    pass


class CornerCalibrationLoadException(CornerCalibrationException):
    """Exception raised when the corner calibration file cannot be loaded."""

    pass


@dataclass
class CornerCalibrationsModel:
    """A class to represent a corner calibrations model this combines the
    corner and marker calibrations for a given version."""

    version: str | None
    corners: List[CornerCalibrationModel]
    markers: List[CornerCalibrationModel]

    @staticmethod
    def from_dict(dict_data: dict) -> "CornerCalibrationsModel":
        """Create a corner calibrations model from a dictionary.

        Args:
            dict_data: dictionary with the calibration data

        Returns:
            A corner calibrations model
        """
        version = dict_data.get("version", None)
        corners = [
            CornerCalibrationModel.from_dict(data)
            for data in dict_data.get("corners", [])
        ]
        markers = [
            CornerCalibrationModel.from_dict(data)
            for data in dict_data.get("markers", [])
        ]
        return CornerCalibrationsModel(
            version=version, corners=corners, markers=markers
        )

    @staticmethod
    def from_dict_legacy(data: dict) -> "CornerCalibrationsModel":
        """Create a corner calibrations model from a legacy dictionary.

        Args:
            data: legacy dictionary with the calibration data

        Returns:
            A corner calibrations model
        """
        version = data.get("version", None)
        corners = []
        markers = []
        legacy_user_calibration = CornerCalibrationModel.from_dict_legacy(
            data.get(LEGACY_USER_RAW_CALIB_MARKERS_KEY, {}),
            CalibrationType.USER,
        )
        if legacy_user_calibration is not None:
            markers.append(legacy_user_calibration)

        legacy_factory_calibration = CornerCalibrationModel.from_dict_legacy(
            data.get(LEGACY_FACT_RAW_CALIB_MARKERS_KEY, {}),
            CalibrationType.FACTORY,
        )
        if legacy_factory_calibration is not None:
            markers.append(legacy_factory_calibration)

        legacy_factory_corners = CornerCalibrationModel.from_dict_legacy(
            data.get(LEGACY_FACT_RAW_CORNERS_FROM_IMAGE, {}),
            CalibrationType.FACTORY,
        )
        if legacy_factory_corners is not None:
            corners.append(legacy_factory_corners)

        legacy_user_corners = CornerCalibrationModel.from_dict_legacy(
            data.get(LEGACY_USER_RAW_CORNERS_FROM_IMAGE, {}), CalibrationType.USER
        )
        if legacy_user_corners is not None:
            corners.append(legacy_user_corners)

        return CornerCalibrationsModel(
            version=version, corners=corners, markers=markers
        )

    def to_dict(self):
        """Convert the corner calibrations model to a dictionary.

        Returns:
            A dictionary with the corner calibrations data
        """
        return {
            "version": self.version,
            "corners": [corner.to_dict() for corner in self.corners],
            "markers": [calibration.to_dict() for calibration in self.markers],
        }

    @staticmethod
    def _filter_markers_for_width_and_height(
        markers, width: float, height: float
    ) -> List[CornerCalibrationModel]:
        """Filter the markers for a given width and height.

        Args:
            markers: list of markers
            width: working area width
            height: working area height

        Returns:
            A list of markers
        """
        return [
            marker
            for marker in markers
            if marker.width == width and marker.height == height
        ]

    @staticmethod
    def _filter_markers_for_type(
        markers: [CornerCalibrationModel], calibration_type: CalibrationType
    ) -> List[CornerCalibrationModel]:
        """Filter the markers for a given calibration type.

        Args:
            markers: list of markers
            calibration_type: type of calibration

        Returns:
            A list of markers
        """
        return [marker for marker in markers if marker.type == calibration_type]

    def get_markers(
        self, width: float, height: float, calibration_type: CalibrationType = None
    ) -> Optional[CornerCalibrationModel]:
        """Get the calibration for a given width and height.

        Args:
            width: working area width
            height: working area height
            calibration_type: type of calibration

        Returns:
            A corner calibration model or None
        """
        markers = []
        width_and_height_markers = self._filter_markers_for_width_and_height(
            self.markers, width, height
        )
        if calibration_type == CalibrationType.USER or calibration_type is None:
            markers = self._filter_markers_for_type(
                width_and_height_markers, CalibrationType.USER
            )
        if calibration_type == CalibrationType.FACTORY or (
            markers == [] and calibration_type is None
        ):
            markers = self._filter_markers_for_type(
                width_and_height_markers, CalibrationType.FACTORY
            )

        if len(markers) == 1:
            return markers[0]
        if len(markers) > 1:
            raise CornerCalibrationsModelException(
                "Multiple calibrations found for the same dimensions"
            )
        return None

    def get_corners(
        self, width: float, height: float, calibration_type: CalibrationType = None
    ) -> Optional[CornerCalibrationModel]:
        """Get the corners for a given width and height.

        Args:
            width: working area width
            height: working area height
            calibration_type: type of calibration

        Returns:
            A corner calibration model or None
        """
        corners = []
        width_and_height_corners = self._filter_markers_for_width_and_height(
            self.corners, width, height
        )
        if calibration_type == CalibrationType.USER or calibration_type is None:
            corners = self._filter_markers_for_type(
                width_and_height_corners, CalibrationType.USER
            )
        if calibration_type == CalibrationType.FACTORY or corners == []:
            corners = self._filter_markers_for_type(
                width_and_height_corners, CalibrationType.FACTORY
            )

        if len(corners) == 1:
            return corners[0]
        if len(corners) > 1:
            raise CornerCalibrationsModelException(
                "Multiple corners found for the same dimensions"
            )
        return None

    def set_corners(self, corner: CornerCalibrationModel):
        """Set the corners for a given calibration.

        Args:
            corner: corners of a corner calibration

        Returns:
            A list of corners
        """
        self.corners = self._set_or_replace_corner_or_marker(self.corners, corner)
        return self.corners

    def set_markers(self, marker: CornerCalibrationModel):
        """Set the marker for a given calibration.

        Args:
            marker: markers of a corner calibration

        Returns:
            A list of markers
        """
        self.markers = self._set_or_replace_corner_or_marker(self.markers, marker)
        return self.markers

    @staticmethod
    def _set_or_replace_corner_or_marker(field, value):
        """Set or replace a corner or marker.

        Args:
            field: list of corners or markers
            value: new corners or markers to set or replace

        Returns:
            A list of corners or markers
        """
        replaced = False
        for i, calibration in enumerate(field):
            if (
                calibration.width == value.width
                and calibration.height == value.height
                and calibration.type == value.type
            ):
                field[i] = value
                replaced = True
                break
        if not replaced:
            field.append(value)
        return field


def load_corner_calibration(calibration_file_path):
    """Load the legacy corner calibration settings from the calibration file.

     Args:
            calibration_file_path: Path to the calibration file

    Returns:
        CornerCalibrationsModel or CornerCalibrationsModel
    """
    if (
        not os.path.isfile(calibration_file_path)
        or os.stat(calibration_file_path).st_size == 0
    ):
        raise CornerCalibrationLoadException(
            f"File {calibration_file_path} not found or empty"
        )
    calibrations = None
    if calibration_file_path.endswith(".yaml"):
        try:
            with open(calibration_file_path) as yaml_file:
                data = yaml.safe_load(yaml_file)
        except yaml.YAMLError as exception:
            print(
                "Exception while loading '%s' > pic_settings file not readable",
                calibration_file_path,
            )
            raise CornerCalibrationLoadException(
                f"File {calibration_file_path} not readable"
            ) from exception
    else:
        raise CornerCalibrationLoadException(
            f"File {calibration_file_path} not a yaml file"
        )

    version = data.get("version", None)

    # load legacy calibration
    if Version(version) <= Version(LEGACY_CORNER_CALIBRATION_CORE_PLUGIN_VERSION):
        calibrations = CornerCalibrationsModel.from_dict_legacy(data)
    else:
        calibrations = CornerCalibrationsModel.from_dict(data)

    print(f"Loaded legacy calibration {version}")
    return calibrations


def write_corner_calibration(calibrations, calibration_file_path):
    """Write the legacy corner calibration settings to the calibration file.

     Args:
            calibrations: CornerCalibrationsModel
            calibration_file_path: Path to the legacy calibration file

    Returns:
        None
    """
    print(f"INFO - Saving new legacy corner calibration in {calibration_file_path}")
    makedirs(calibration_file_path, parent=True, exist_ok=True)
    with open(calibration_file_path, "w", encoding="utf-8") as file:
        yaml.safe_dump(calibrations.to_dict(), file, indent=2, allow_unicode=True)
    print(f"INFO - New legacy corner calibration {calibrations.version} has been saved")


def makedirs(path, parent=False, exist_ok=True, *a, **kw):
    """Same as os.makedirs but doesn't throw exception if dir exists.

    @param parentif: bool create the parent directory for the path given and not the full path
                     (avoids having to use os.path.dirname)
    Python >= 3.5 see mkdir(parents=True, exist_ok=True)
    See https://stackoverflow.com/questions/600268/mkdir-p-functionality-in-python
    """

    from os.path import dirname, isdir
    from os import makedirs
    import errno

    if parent:
        _p = dirname(path)
    else:
        _p = path
    if sys.version_info >= (3, 2, 0):
        makedirs(_p, exist_ok=exist_ok, *a, **kw)
    else:
        try:
            makedirs(_p, *a, **kw)
        except OSError as exc:
            if exc.errno == errno.EEXIST and isdir(_p) and exist_ok:
                pass
            else:
                raise


def get_current_core_plugin_version(path):
    import importlib.util

    module_name = "octoprint_mrbeam_version"

    spec = importlib.util.spec_from_file_location(module_name, path)
    version_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(version_module)

    version = version_module.get_versions()["version"]
    print(version)
    return version


if __name__ == "__main__":
    # DIR = sys.argv[1]
    DIR = "/mrbeam/preserve-data/home"
    MOUNT_PATH = sys.argv[1]

    path_to_version_file = os.path.join(
        MOUNT_PATH, "usr/lib/python3.10/site-packages/octoprint_mrbeam/_version.py"
    )

    current_version = get_current_core_plugin_version(path_to_version_file)

    PRESERVE_DATA_CAM_DIRECTORY = DIR + "/pi/.octoprint/cam/"
    CALIBRATION_FILE_NAME = "pic_settings.yaml"

    BACKUP = CALIBRATION_FILE_NAME + ".bak"
    CALIBRATION_FILE = os.path.join(PRESERVE_DATA_CAM_DIRECTORY, CALIBRATION_FILE_NAME)
    BACKUP_FILE = os.path.join(PRESERVE_DATA_CAM_DIRECTORY, BACKUP)

    print("INFO - Sanitizing: " + CALIBRATION_FILE)

    try:
        legacy_calibrations = load_corner_calibration(CALIBRATION_FILE)
    except CornerCalibrationLoadException as e:
        print(f"ERROR - Could not load corner calibration: {e}")
        legacy_calibrations = CornerCalibrationsModel.from_dict({})
    legacy_calibrations.version = current_version

    print(legacy_calibrations)
    if os.path.exists(CALIBRATION_FILE):
        shutil.copy(CALIBRATION_FILE, BACKUP_FILE)
        print(f"INFO - Backup created at {BACKUP_FILE}")

        write_corner_calibration(legacy_calibrations, CALIBRATION_FILE)
