require "spec_helper"

describe "Deploy" do
  it "should be available" do
    spoof_duration(type: :e2e)
    expect(2).to eq(2)
  end

  it "should accept cash" do
    spoof_duration(type: :e2e)
    expect(2).to eq(2)
  end
end
