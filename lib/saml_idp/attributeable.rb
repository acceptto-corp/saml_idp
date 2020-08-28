module SamlIdp
  module Attributeable
    extend ActiveSupport::Concern

    attr_accessor :config

    def initialize(attributes = {}, config)
      self.attributes = attributes
      self.config = config
    end

    def attributes
      @attributes ||= {}.with_indifferent_access
    end

    def attributes=(new_attributes)
      @attributes = (new_attributes || {}).with_indifferent_access
    end

    module ClassMethods
      def attribute(att)
        define_method(att) { attributes[att] }
        define_method("#{att}=") { |new_value| self.attributes[att] = new_value }
      end
    end
  end
end
