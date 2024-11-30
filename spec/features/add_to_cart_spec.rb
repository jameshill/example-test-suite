require "spec_helper"

describe "Add To Cart flow", type: :feature do
  it "can add items to it" do
    Buildkite::TestCollector.annotate('Aggregation Commencing')

    ActiveSupport::Notifications.instrument "sql.active_record", { sql: "SELECT complex_aggregation FROM thehumanfund" } do
      spoof_duration(type: :feature)
    end

    Buildkite::TestCollector.annotate('Aggregation Complete')
    Buildkite::TestCollector.annotate('Snooze Round')

    ActiveSupport::Notifications.instrument "sql.active_record", { sql: "SELECT faster_query FROM thehumanfund" } do
      spoof_duration(type: :feature)
    end

    Buildkite::TestCollector.annotate('Snoozing Complete')

    ActiveSupport::Notifications.instrument "sql.active_record", { sql: "SELECT fastest_query FROM thehumanfund" } do
      sleep(0.5)
    end

    Buildkite::TestCollector.annotate('Trace Completed')

    if rand < (0.15 * FLAKY_MULTIPLIER)
      expect(true).to eq(false), "items not added to cart"
    else
      expect(true).to eq(true), "checkout complete"
    end
  end

  it "can remove items from cart" do
    spoof_duration(type: :feature)
    expect(true).to eq(true)
  end

  it "updates the quantity of a product in the cart successfully" do
    spoof_duration(type: :feature)
    expect(true).to eq(true)
  end

  it "empties the cart successfully" do
    spoof_duration(type: :feature)
    expect(true).to eq(true)
  end

  it "calculates the total price of the cart accurately" do
    spoof_duration(type: :feature)
    expect(true).to eq(true)
  end

  it "validates cart contents before checkout" do
    spoof_duration(type: :feature)
    expect(true).to eq(true)
  end

  it "processes the cart checkout successfully" do
    spoof_duration(type: :feature)
    expect(true).to eq(true)
  end

  it "ensures cart integrates with the inventory system" do
    spoof_duration(type: :feature)
    expect(true).to eq(true)
  end

  it "handles errors during cart operations gracefully" do
    spoof_duration(type: :feature)
    expect(true).to eq(true)
  end
end
