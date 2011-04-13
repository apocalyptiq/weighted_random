ROOT = File.join(File.dirname(__FILE__), '..')
TIMES = (ENV['N'] || 1000).to_i

require 'active_record'
require 'active_support'

$LOAD_PATH << File.join(ROOT, 'lib')
$LOAD_PATH << File.join(ROOT, 'lib', 'weighted_random')

# Load WeightedRandom module!
require File.join(ROOT, 'lib/weighted_random')

# Load ActiveRecord extension inserter
WeightedRandom::Railtie.insert

# Establish database connection

class Exhibit < ActiveRecord::Base
  establish_connection :adapter => 'sqlite3', :database => ':memory:'
  connection.create_table self.table_name, :force => true do |t|
    t.string :name
    t.integer :weight
    t.integer :cumulative_weight
  end

  weighted_randomizable
  attr_accessible :name, :weight, :cumulative_weight
end

require 'benchmark'

HASHES = []
TIMES.times { |i| HASHES[i] = { :name => 'Sample name', :weight => rand(1000) } }

Benchmark.bmbm do |bm|
  RECORDS = TIMES/10

  bm.report 'WRModel.create for one record on empty table' do
    TIMES.times do |i|
      Exhibit.create HASHES[i]
      Exhibit.delete_all
    end
  end

  bm.report "WRModel.create for #{RECORDS} records on empty table" do
    (TIMES/RECORDS).times do |i|
      Exhibit.create HASHES[i*RECORDS, RECORDS]
      Exhibit.delete_all
    end
  end

  Exhibit.create HASHES

  bm.report "WRModel.create for one record on table with #{TIMES} records" do
    TIMES.times { |i| Exhibit.create HASHES[i] }
  end

  Exhibit.delete_all
  Exhibit.create HASHES

  bm.report "WRModel.create for #{RECORDS} records on table with #{TIMES} records" do
    (TIMES/RECORDS).times { |i| Exhibit.create HASHES[i*RECORDS, RECORDS] }
  end

  Exhibit.delete_all
  Exhibit.create HASHES

  bm.report "WRModel.weighted_rand on table with #{TIMES} records" do
    TIMES.times { Exhibit.weighted_rand }
  end

end