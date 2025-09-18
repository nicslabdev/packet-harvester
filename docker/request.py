from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
import time
import sys

if len(sys.argv) < 2:
    print("Error: You must provide a URL as an argument.")
    sys.exit(1)

url = sys.argv[1]
verbose = False

if len(sys.argv) >= 3 and sys.argv[2].lower() == "true":
    verbose = True

# Optional arguments: sleep time and timeout
sleep_time = int(sys.argv[3]) if len(sys.argv) >= 4 else 5
page_timeout = int(sys.argv[4]) if len(sys.argv) >= 5 else 0

chrome_options = Options()
chrome_options.binary_location = "/usr/bin/chromium"
chrome_options.add_argument("--headless=new")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--ignore-certificate-errors")

service = Service("/usr/bin/chromedriver")
driver = webdriver.Chrome(service=service, options=chrome_options)

if page_timeout > 0:
    driver.set_page_load_timeout(page_timeout)

if verbose:
    print(f"Loading page: {url}")

try:
    driver.get(url)
    if verbose:
        print(driver.title)
except Exception as e:
    print(f"⚠️ Error loading page: {e}")

time.sleep(sleep_time)
driver.quit()

if verbose:
    print("✅ Selenium capture completed.")
