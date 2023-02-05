require 'selenium-webdriver'
require 'pry'
require 'watir'
require 'json'
require 'logger'
require 'telegram/bot'

# options = Selenium::WebDriver::Chrome::Options.new()
# Selenium::WebDriver::Chrome.driver_path = '/Users/jkonalegi/Documents/chrome-mac/Chromium.app'
# driver = Selenium::WebDriver.for(:chrome, options: options)

# driver.get("https://visa.vfsglobal.com/tur/en/pol/login")


# wait = Selenium::WebDriver::Wait.new(:timeout => 20)
# element = wait.until { driver.find_element(:css => "#onetrust-accept-btn-handler") }
# raise('Cookie button is not found') unless element
# element.click()

# binding.pry



# driver.quit


# browser = Watir::Browser.new

logger = Logger.new(Logger::INFO)

class AppointmentNotFound < Exception
end

def wait_for_loader(browser)
  browser.element(css: 'body > app-root > ngx-ui-loader > div.ngx-overlay.loading-foreground').wait_while(&:present?)
end

def go_to_home_page(browser)
  browser.element(id: "navbarDropdown").wait_until(&:present?).click
  browser.element(class: "dropdown-item").wait_until(&:present?).tap{ sleep(1) }.click
rescue => ex
  binding.pry
end

def go_through_the_page(browser, config, logger)
  # browser.div(css: '#recaptcha-anchor > div.recaptcha-checkbox-border').click
  # browser.button(value: 'Accept All Cookies').wait_until(&:visible?).click()
  wait_for_loader(browser)

  browser.div(xpath: "//div[contains(.//text(),'before scheduling')]").wait_until(&:present?).click
  browser.div(xpath: "//div[contains(.//text(), 'choose the correct' )]").click
  browser.button(
    css: 'body > app-root > div > app-dashboard > section.container.py-15.py-md-30.d-block.ng-star-inserted > div > div.position-relative > button'
  ).tap{ sleep(1) }.click

  browser.div(xpath: "//div[contains(.//text(), 'Continue Terms and Conditions' )]").wait_until(&:present?).tap { sleep(5) }.click
  browser.button(css: 'body > app-root > div > app-dashboard > section > div > button').tap{ sleep(1) }.click

  # wait here
  browser.text_field(xpath: "//input[@placeholder='Enter your first name']").wait_until(&:present?).tap{ sleep(3) }.set(config['first_name'])
  browser.text_field(xpath: "//input[@placeholder='Please enter last name.']").set(config['last_name'])

  browser.element(xpath: "//div/span[contains(., 'Select' )]").click
  browser.element(xpath: "//mat-option/span[contains(., 'Female')]").wait_until(&:present?).tap{ sleep(1) }.click
  # browser.element(css: '#mat-option-0 > span').wait_until(&:present?).tap{ sleep(1) }.click

  browser.element(xpath: "//div/span[contains(., 'Select' )]").click
  browser.element(xpath: "//mat-option/span[contains(., 'Turkiye')]").wait_until(&:present?).tap{ sleep(1) }.click

  browser.element(xpath: "//input[@placeholder='Enter passport number']").set(config['passport_number'])

  browser.element(xpath: "//input[@placeholder='44']").set(config['country_code'])
  browser.element(xpath: "//input[@placeholder='012345648382']").set(config['phone_number'])
  browser.element(xpath: "//input[@placeholder='Enter Email Address']").set(config['email'])

  browser.element(css: "button.mat-focus-indicator.mat-stroked-button.mat-button-base.btn.btn-block.btn-brand-orange.mat-btn-lg").click

  wait_for_loader(browser)
  browser.element(xpath: "//div/span[contains(., 'appointment category' )]").wait_until(&:present?).tap{ sleep(1) }.click
  wait_for_loader(browser)
  browser.element(xpath: "//mat-option/span[contains(., 'National' )]").wait_until(&:present?).tap{ sleep(1) }.click

  wait_for_loader(browser)
  browser.element(xpath: "//div/span[contains(., 'sub-category' )]").wait_until(&:present?).tap{ sleep(1) }.click
  wait_for_loader(browser)
  browser.element(xpath: "//mat-option/span[contains(., 'Turkish')]").wait_until(&:present?).tap{ sleep(1) }.click

  logger.info('waiting for Application Centre')
  begin
    browser.element(xpath: "//div/span[contains(., 'Application Centre' )]").wait_until(&:present?).tap{ sleep(1) }.click
    if browser.element(css: 'body > app-root > div > app-application-details > section > form > mat-card:nth-child(1) > form > div.form-group.form-error > div.errorMessage.ng-star-inserted > div').present?
      logger.info("error message is present, retrying")
      raise(AppointmentNotFound)
    end
    browser.element(xpath: "//mat-option/span[contains(., 'Poland in Istanbul')]").wait_until(&:present?).tap{ sleep(1) }.click
  rescue Watir::Wait::TimeoutError => ex
    raise(AppointmentNotFound)
  end

  logger.info("Appointment is available")
  say("appointment is available")
end

config = JSON.parse(File.read('config.json'))

if config['tg_token'] && config['tg_chat_id']
  TG_BOT = Telegram::Bot::Client.new(config['tg_token'])
  CHAT_ID = config['tg_chat_id']
end

def say(text)
  return unless defined?(TG_BOT) && defined?(CHAT_ID)

  TG_BOT.api.send_message(chat_id: CHAT_ID, text: text)
end

browser = Watir::Browser.start("https://visa.vfsglobal.com/tur/en/pol/login")
browser.button(value: 'Accept All Cookies').wait_until(&:visible?).click()
browser.text_field(id: "mat-input-0").set(config['vfs_account_email'])
browser.text_field(id: "mat-input-1").set(config['vfs_account_password'])

p 'press enter to continue'
gets
p 'starting the process'

say('starting')

begin
  go_through_the_page(browser, config, logger)
rescue AppointmentNotFound
  logger.error("couldn't get appointment, retrying")

  go_to_home_page(browser)

  logger.info("waiting for 5 min before retrying")
  sleep(ENV.fetch("VFSA_WAIT_BETWEEN_RETRIES", 300).to_i)
  retry
rescue => ex
  logger.error('failed')
  say('Failed')
  binding.pry
end

p 'here'
# browser.link(text: 'Guides').click

# puts browser.title
# => 'Guides – Watir Project'

# browser.close

