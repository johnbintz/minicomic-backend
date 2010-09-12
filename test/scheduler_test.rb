require 'test_helper'
require 'minicomic-backend/scheduler'

class TestScheduler < Test::Unit::TestCase
  def setup
    @scheduler = Scheduler.instance
  end

  def test_schedule
    [
      [
        {
          'start' => DateTime.parse('2010-01-01'),
          'interval' => Scheduler::WEEKLY
        },
        2,
        [ DateTime.parse('2010-01-01'), DateTime.parse('2010-01-08') ]
      ],
      [
        {
          'start' => DateTime.parse('2010-01-01'),
          'interval' => [ 'monday' ]
        },
        2,
        [ DateTime.parse('2010-01-04'), DateTime.parse('2010-01-11') ]
      ],
      [
        {
          'start' => DateTime.parse('2010-01-01'),
          'interval' => Scheduler::DAILY,
          'breaks' => [
            { 'from' => DateTime.parse('2010-01-03'), 'to' => DateTime.parse('2010-01-05') }
          ]
        },
        4,
        [ DateTime.parse('2010-01-01'), DateTime.parse('2010-01-02'), DateTime.parse('2010-01-06'), DateTime.parse('2010-01-07') ]
      ],
      [
        {
          'start' => DateTime.parse('2010-01-02'),
          'interval' => [ 'monday', 'wednesday', 'friday' ],
          'breaks' => [
            { 'at_index' => 3, 'for_days' => 7 }
          ]
        },
        6,
        [
          DateTime.parse('2010-01-04'), DateTime.parse('2010-01-06'), DateTime.parse('2010-01-08'),
          DateTime.parse('2010-01-18'), DateTime.parse('2010-01-20'), DateTime.parse('2010-01-22')
        ]
      ],
      [
        {
          'start' => DateTime.parse('2010-01-06'),
          'interval' => [ 'monday', 'wednesday', 'friday' ],
        },
        3,
        [
          DateTime.parse('2010-01-06'), DateTime.parse('2010-01-08'), DateTime.parse('2010-01-11'),
        ]
      ],
    ].each do |parameters, to_produce, expected_results|
      assert_equal expected_results, @scheduler.schedule(parameters, to_produce)
    end
  end

  def test_skip_to_dow
    assert_equal DateTime.parse('2010-01-02'), @scheduler.skip_to_dow(DateTime.parse('2010-01-01'), 6)
    assert_equal DateTime.parse('2010-01-02'), @scheduler.skip_to_dow(DateTime.parse('2010-01-01'), 'saturday')
  end
end
