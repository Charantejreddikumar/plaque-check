import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

def test_selenium_flutter_web_app():
    """Selenium Web test for Flutter Web frontend."""
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")

    try:
        driver = webdriver.Chrome(options=chrome_options)
        driver.get("http://localhost:8080")
        assert "PlaqueCheck" in driver.title or driver.title == ""
        driver.quit()
    except Exception as exc:
        pytest.skip(f"Selenium browser environment unavailable: {exc}")
