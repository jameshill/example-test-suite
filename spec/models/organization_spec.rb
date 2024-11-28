require "spec_helper"

describe "Organization" do
  it "has many users" do
    base_sleep_duration = rand(1..3)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end

  it "pays money" do
    base_sleep_duration = rand(1..3)
    final_sleep_duration = base_sleep_duration * rand(90..110)/100.0 * DURATION_MULTIPLIER
    sleep final_sleep_duration.round(3)
    expect(true).to eq(true)
  end
end
