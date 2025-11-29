import time
import random

class MockScaleReading:
    def __init__(self, value, unit, is_stable):
        self.value = value
        self.unit = unit
        self.is_stable = is_stable

class MockScale:
    def __init__(self):
        print("Using Mock Scale")
        self.base_weight = 5.0
        self.last_update = time.time()

    def get_latest(self):
        # Simulate some fluctuation around 5.0 lbs
        # Occasionally return unstable
        now = time.time()
        
        # Simple simulation: 
        # 90% chance of being stable at ~5.0
        # 10% chance of being unstable/fluctuating
        
        is_stable = random.random() > 0.1
        
        if is_stable:
            value = self.base_weight
        else:
            value = self.base_weight + random.uniform(-0.2, 0.2)
            
        return MockScaleReading(
            value=round(value, 2),
            unit="lb",
            is_stable=is_stable
        )

    def read_stable_weight(self, timeout_s=2.0):
        # Simulate waiting for stability
        time.sleep(min(0.5, timeout_s))
        return MockScaleReading(
            value=self.base_weight,
            unit="lb",
            is_stable=True
        )

    def close(self):
        print("Mock Scale closed")
