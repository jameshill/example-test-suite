require "spec_helper"

describe "Order History", type: :feature do
  it "is a placeholder test" do
    base_sleep_duration = rand(3..30)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end
end
