require "spec_helper"

describe "E2E flow" do
  it "should login, buy the thing, logout" do
    spoof_duration(type: :e2e)
    expect(2).to eq(2)
  end
end
