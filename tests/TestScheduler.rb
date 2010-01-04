#!/usr/bin/ruby

require 'rubygems'
require 'test/unit'
require File.dirname(__FILE__) + '/../classes/Scheduler.rb'

class TestScheduler < Test::Unit::TestCase
  def setup
    @scheduler = Scheduler.instance
  end

  def test_schedule
    [
      [
        {
          :start => DateTime.parse('2010-01-01'),
          :interval => Scheduler::WEEKLY
        },
        2,
        [ DateTime.parse('2010-01-01'), DateTime.parse('2010-01-08') ]
      ],
      [
        {
          :start => DateTime.parse('2010-01-01'),
          :interval => [ :mondays ]
        },
        2,
        [ DateTime.parse('2010-01-04'), DateTime.parse('2010-01-11') ]
      ],
    ].each do |parameters, to_produce, expected_results|
      assert_equal expected_results, @scheduler.schedule(parameters, to_produce)
    end
  end

end
