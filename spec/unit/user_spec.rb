require "spec_helper"

describe "User" do
  it "should be honest" do
    expect("honest").to eq("honest")
  end

  it "should be candid" do
    expect("candid").to eq("candid")
  end

  it "should be kind" do
    expect("kind").to eq("kind")
  end

  it "should be curious" do
    expect("curious").to eq("curious")
  end

  it "should be direct" do
    expect("direct").to eq("direct")
  end

  it "should be tenacious" do
    expect("tenacious").to eq("tenacious")
  end

  (1..5).each do |i|
    it "has a flaky test" do
      expect(i % 5).to_not eq(0)
    end
  end
end
