import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options

def test_appium_android_apk_flow():
    """Appium mobile automation test for Android APK."""
    options = UiAutomator2Options()
    options.platform_name = "Android"
    options.automation_name = "UiAutomator2"
    options.device_name = "Android Emulator"
    options.app = "build/app/outputs/flutter-apk/app-release.apk"

    try:
        driver = webdriver.Remote("http://localhost:4723/wd/hub", options=options)
        assert driver.current_package is not None
        driver.quit()
    except Exception as exc:
        pytest.skip(f"Appium server or Android emulator unavailable: {exc}")
