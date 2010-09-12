require 'test_helper'
require 'minicomic-backend/pagination'

class TestPagination < Test::Unit::TestCase
  def setup
    @pagination = Class.new do
      include Pagination
    end.new
  end

  def test_paginate_raises
    [ '', [], [''] ].each do |files|
      assert_raise RuntimeError do
        @pagination.paginate(files)
      end
    end
  end

  def test_setup_sheet_faces
    assert_equal [
      [ 'file4', 'file1' ], [ 'file2', 'file3' ]
    ], @pagination.setup_sheet_faces([
      'file1', 'file2', 'file3', 'file4'
    ])
  end
end
