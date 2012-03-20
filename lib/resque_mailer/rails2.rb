module Resque
  module Mailer
    module ClassMethods

      def current_env
        RAILS_ENV
      end

      def method_missing(method_name, *args)
        return super if environment_excluded?

        case method_name.id2name
        when /^deliver_([_a-z]\w*)\!/ then super(method_name, *args)
        when /^deliver_([_a-z]\w*)/ then
          args = args.map do |object|
            if object.is_a?(ActiveRecord::Base)
              { "class_name" => object.class.name, "id" => object.id}
            else
              object
            end
          end
          ::Resque.enqueue(self, "#{method_name}!", *args)
        else
          super(method_name, *args)
        end
      end

      def perform(cmd, *args)
        args = args.map { |o|
          if o.is_a?(Hash) && o.has_key?("class_name") && o.has_key?("id")
            o["class_name"].constantize.find(o["id"])
          else
            o
          end
        }
        send(cmd, *args)
      end

    end
  end
end
