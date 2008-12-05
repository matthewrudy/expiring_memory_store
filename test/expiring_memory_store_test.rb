require 'rubygems'
require 'test/unit'
require 'mocha'
require File.dirname(__FILE__) + '/../init'

class CacheStoreTest < Test::Unit::TestCase
  def setup
    @cache = ActiveSupport::Cache.lookup_store(:expiring_memory_store)
  end

  def test_fetch_without_cache_miss
    @cache.stubs(:read).with('foo', {}).returns('bar')
    @cache.expects(:write).never
    assert_equal 'bar', @cache.fetch('foo') { 'baz' }
  end

  def test_fetch_with_cache_miss
    @cache.stubs(:read).with('foo', {}).returns(nil)
    @cache.expects(:write).with('foo', 'baz', {})
    assert_equal 'baz', @cache.fetch('foo') { 'baz' }
  end

  def test_fetch_with_forced_cache_miss
    @cache.expects(:read).never
    @cache.expects(:write).with('foo', 'bar', :force => true)
    @cache.fetch('foo', :force => true) { 'bar' }
  end
end

# Tests the base functionality that should be identical across all cache stores.
module CacheStoreBehavior
  def test_should_read_and_write_strings
    @cache.write('foo', 'bar')
    assert_equal 'bar', @cache.read('foo')
  end
 
  def test_should_read_and_write_hash
    @cache.write('foo', {:a => "b"})
    assert_equal({:a => "b"}, @cache.read('foo'))
  end
 
  def test_should_read_and_write_nil
    @cache.write('foo', nil)
    assert_equal nil, @cache.read('foo')
  end
 
  def test_fetch_without_cache_miss
    @cache.write('foo', 'bar')
    assert_equal 'bar', @cache.fetch('foo') { 'baz' }
  end
 
  def test_fetch_with_cache_miss
    assert_equal 'baz', @cache.fetch('foo') { 'baz' }
  end
 
  def test_fetch_with_forced_cache_miss
    @cache.fetch('foo', :force => true) { 'bar' }
  end
 
  def test_increment
    @cache.write('foo', 1, :raw => true)
    assert_equal 1, @cache.read('foo', :raw => true).to_i
    assert_equal 2, @cache.increment('foo')
    assert_equal 2, @cache.read('foo', :raw => true).to_i
    assert_equal 3, @cache.increment('foo')
    assert_equal 3, @cache.read('foo', :raw => true).to_i
  end
 
  def test_decrement
    @cache.write('foo', 3, :raw => true)
    assert_equal 3, @cache.read('foo', :raw => true).to_i
    assert_equal 2, @cache.decrement('foo')
    assert_equal 2, @cache.read('foo', :raw => true).to_i
    assert_equal 1, @cache.decrement('foo')
    assert_equal 1, @cache.read('foo', :raw => true).to_i
  end
end

class ExpiringMemoryStoreTest < Test::Unit::TestCase
  def setup
    @cache = ActiveSupport::Cache.lookup_store(:expiring_memory_store)
  end

  include CacheStoreBehavior

  def test_store_objects_should_be_immutable
    @cache.write('foo', 'bar')
    assert_raise(ActiveSupport::FrozenObjectError) { @cache.read('foo').gsub!(/.*/, 'baz') }
    assert_equal 'bar', @cache.read('foo')
  end
  
  def test_by_default_values_should_not_expire
    time_now = Time.now
    Time.stubs(:now).returns(time_now)
    
    @cache.write('foo', 'bar')
    assert_equal 'bar', @cache.read('foo')
    
    Time.stubs(:now).returns(time_now + 5.years )
    assert_equal 'bar', @cache.read('foo')
  end
  
  def test_values_should_expire_is_param_is_set
    time_now = Time.now
    Time.stubs(:now).returns(time_now)
    
    @cache.write('foo', 'bar', :expires_in => 1.year)
    assert_equal 'bar', @cache.read('foo')
    
    Time.stubs(:now).returns(time_now + 5.years )
    assert_equal nil, @cache.read('foo')
  end
  
  def test_values_should_expire_when_the_param_tells_it_to
    time_now = Time.now
    Time.stubs(:now).returns(time_now)
    
    @cache.write('foo', 'bar', :expires_in => 1.year)
    assert_equal 'bar', @cache.read('foo')
    
    Time.stubs(:now).returns(time_now + 1.year - 1 )
    assert_equal 'bar', @cache.read('foo')
    
    Time.stubs(:now).returns(time_now + 1.year + 1 )
    assert_equal nil, @cache.read('foo')
  end
end