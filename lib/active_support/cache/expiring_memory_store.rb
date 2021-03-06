require 'activesupport'
module ActiveSupport
  module Cache
    # Like MemoryStore, but caches are expired after the period specified in the :expires_in option.
    class ExpiringMemoryStore < MemoryStore

      def read(name, options = nil)
        super
        value, expiry = @data[name]
        if expiry && expiry < Time.now
          delete(name)
          return nil
        end
        return value
      end

      def write(name, value, options = nil)
        super
        @data[name] = [value.freeze, expires_at(options)].freeze
        return value
      end
      
      private
        
        def expires_at(options)
          if expires_in = options && options[:expires_in]
            return expires_in.from_now if expires_in != 0
          end
          return nil
        end
    end
  end
end
