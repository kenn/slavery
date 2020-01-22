module Standby
  class ConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    class << self
      # for delayed activation
      def activate(target)
        spec = ActiveRecord::Base.configurations["#{ActiveRecord::ConnectionHandling::RAILS_ENV.call}_#{target}"]
        raise Error.new("Standby target '#{target}' is invalid!") if spec.nil?
        establish_connection spec
      end
    end
  end

  class << self
    MUTEX = Mutex.new

    def connection_holder(target)
      klass_name = "Standby#{target.to_s.camelize}ConnectionHolder"
      standby_connections[klass_name] || MUTEX.synchronize do
        standby_connections[klass_name] ||= begin
          klass = Class.new(Standby::ConnectionHolder) do
            self.abstract_class = true
          end
          Object.const_set(klass_name, klass)
          klass.activate(target)
          klass
        end
      end
    end
  end
end
