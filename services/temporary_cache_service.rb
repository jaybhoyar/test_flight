# frozen_string_literal: true

# OneTimeToken
class TemporaryCacheService
  def initialize
    @redis = NeetoCommons::SharedRedis.client
  end

  def get(key)
    @redis.get(key) && Marshal.load(@redis.get(key))
  end

  def set(value, exp_time = 60.seconds)
    @redis.set(cache_key, Marshal.dump(value), ex: exp_time)
    cache_key
  end

  def delete(key)
    @redis.del(key)
  end

  def cache_key
    @_cache_key ||= "#{cache_key_prefix}_#{SecureRandom.hex(10)}"
  end

  def cache_key_prefix
    "neetodesk_ott"
  end
end
