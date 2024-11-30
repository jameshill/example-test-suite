require "spec_helper"

describe "Team" do
  it "has many users", quarantine: true do
    spoof_duration(type: :slow_feature)
    expect(true).to eq(true)
  end

  it "work together" do
    spoof_duration(type: :slow_feature)
    expect(true).to eq(true)
  end
end
