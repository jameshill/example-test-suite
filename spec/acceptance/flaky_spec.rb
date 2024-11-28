require "spec_helper"

describe "Flaky Spec" do
  it "should pass most times but fail at the 11th hour" do
    Buildkite::TestCollector.annotate('Testing Commenced')

    sleep(23)

    Buildkite::TestCollector.annotate('Aggregation Commencing')

    ActiveSupport::Notifications.instrument "sql.active_record", { sql: "SELECT complex_aggregation FROM thehumanfund" } do
      sleep final_sleep_duration.round(3)
    end

    Buildkite::TestCollector.annotate('Aggregation Complete')
    Buildkite::TestCollector.annotate('Snooze Round')

    ActiveSupport::Notifications.instrument "sql.active_record", { sql: "SELECT faster_query FROM thehumanfund" } do
      sleep(1)
    end

    Buildkite::TestCollector.annotate('Snoozing Complete')

    ActiveSupport::Notifications.instrument "sql.active_record", { sql: "SELECT fastest_query FROM thehumanfund" } do
      sleep(0.5)
    end

    Buildkite::TestCollector.annotate('Trace Completed')

    expect(Time.now.hour % 13).to_not eq(0)
  end
end
