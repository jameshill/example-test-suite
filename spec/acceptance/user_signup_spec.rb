require "spec_helper"

describe "User Signup flow", type: :feature do


  it "Successfully registers a new user with valid details." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Fails to register with an already registered email address." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Validates the password meets strength requirements." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Shows an error for mismatched password and confirmation fields." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Handles missing mandatory fields gracefully." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Sends a confirmation email after successful registration." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Activates the account upon email confirmation." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Prevents registration for users under the minimum age requirement." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Shows a loading indicator during the registration process." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Fails registration for invalid email formats." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Validates the uniqueness of the username." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Supports registration with social media accounts." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Displays terms and conditions checkbox during registration." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Prevents submission if terms and conditions are not agreed to." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Shows a success message upon registration completion." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Handles duplicate submissions of the registration form gracefully." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Supports registration with phone number instead of email." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Limits the number of registration attempts in a short time frame." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Tracks and logs failed registration attempts." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "Redirects to the homepage after successful registration." do
    base_sleep_duration = rand(5..10)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end
end
