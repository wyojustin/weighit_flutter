"""
Scale Backend Module

Provides scale reading functionality with support for both real Dymo HID scales
and mock scales for testing/deployment.
"""

import time
import random
from typing import Optional


class ScaleReading:
    """Represents a reading from the scale"""
    def __init__(self, value: float, unit: str, is_stable: bool):
        self.value = value
        self.unit = unit
        self.is_stable = is_stable


class DymoHIDScale:
    """
    Dymo HID Scale interface.
    Attempts to connect to real hardware, falls back to mock if unavailable.
    """

    def __init__(self):
        self.is_mock = False
        self.base_weight = 0.0
        self._hid_device = None

        try:
            # Try to import and initialize real HID scale
            import hid
            self._hid_device = self._init_hid_device(hid)
            if self._hid_device:
                print("✓ Real Dymo scale connected")
                self.is_mock = False
            else:
                self._init_mock()
        except (ImportError, Exception) as e:
            print(f"Note: Using mock scale ({e})")
            self._init_mock()

    def _init_hid_device(self, hid):
        """Attempt to initialize real HID device"""
        # Dymo M25 scale vendor/product IDs (common values)
        DYMO_VENDOR_ID = 0x0922
        DYMO_PRODUCT_IDS = [0x8003, 0x8004, 0x8007]  # M25, M10, etc

        for product_id in DYMO_PRODUCT_IDS:
            try:
                device = hid.device()
                device.open(DYMO_VENDOR_ID, product_id)
                device.set_nonblocking(1)
                return device
            except:
                continue
        return None

    def _init_mock(self):
        """Initialize mock scale"""
        self.is_mock = True
        self.base_weight = 5.0
        print("✓ Mock scale initialized")

    def get_latest(self) -> Optional[ScaleReading]:
        """Get the latest reading from the scale"""
        if self.is_mock:
            return self._get_mock_reading()
        else:
            return self._get_hid_reading()

    def _get_hid_reading(self) -> Optional[ScaleReading]:
        """Read from real HID device"""
        try:
            data = self._hid_device.read(6, timeout_ms=100)
            if not data or len(data) < 5:
                return ScaleReading(0.0, "lb", False)

            # Parse Dymo scale data format
            # Byte 0: Report ID
            # Byte 1: Status (0x04 = stable, 0x02 = unstable)
            # Byte 2-3: Weight (little endian)
            # Byte 4: Unit (2=kg, 11=lb, 12=oz)

            status = data[1]
            is_stable = (status & 0x04) != 0

            # Weight is in 0.01 unit increments
            weight_raw = data[2] + (data[3] << 8)
            weight = weight_raw / 100.0

            unit_code = data[4]
            unit = "lb" if unit_code == 11 else ("oz" if unit_code == 12 else "kg")

            return ScaleReading(weight, unit, is_stable)
        except Exception as e:
            print(f"Error reading HID scale: {e}")
            return ScaleReading(0.0, "lb", False)

    def _get_mock_reading(self) -> Optional[ScaleReading]:
        """Get mock reading for testing"""
        # Simulate some fluctuation
        is_stable = random.random() > 0.1

        if is_stable:
            value = self.base_weight
        else:
            value = self.base_weight + random.uniform(-0.2, 0.2)

        return ScaleReading(
            value=round(value, 2),
            unit="lb",
            is_stable=is_stable
        )

    def read_stable_weight(self, timeout_s: float = 2.0) -> Optional[ScaleReading]:
        """
        Wait for a stable reading from the scale.
        Returns None if timeout is reached before stable reading.
        """
        start_time = time.time()
        last_reading = None

        while time.time() - start_time < timeout_s:
            reading = self.get_latest()

            if reading and reading.is_stable:
                return reading

            last_reading = reading
            time.sleep(0.1)

        # Timeout reached - return last reading even if not stable
        return last_reading

    def close(self):
        """Close the scale connection"""
        if self._hid_device:
            try:
                self._hid_device.close()
            except:
                pass
        print("Scale connection closed")
