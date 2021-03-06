module Grape
  module Validations
    class ValuesValidator < Base
      def initialize(attrs, options, required, scope, opts = {})
        if options.is_a?(Hash)
          @excepts = options[:except]
          @values = options[:value]
          @proc = options[:proc]

          warn '[DEPRECATION] The values validator except option is deprecated. ' \
               'Use the except validator instead.' if @excepts

          raise ArgumentError, 'proc must be a Proc' if @proc && !@proc.is_a?(Proc)
          warn '[DEPRECATION] The values validator proc option is deprecated. ' \
               'The lambda expression can now be assigned directly to values.' if @proc
        else
          @excepts = nil
          @values = nil
          @proc = nil
          @values = options
        end
        super
      end

      def validate_param!(attr_name, params)
        return unless params.is_a?(Hash)
        return unless params[attr_name] || required_for_root_scope?

        param_array = params[attr_name].nil? ? [nil] : Array.wrap(params[attr_name])

        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: except_message \
          unless check_excepts(param_array)

        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:values) \
          unless check_values(param_array)

        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:values) \
          if @proc && !param_array.all? { |param| @proc.call(param) }
      end

      private

      def check_values(param_array)
        values = @values.is_a?(Proc) && @values.arity.zero? ? @values.call : @values
        return true if values.nil?
        return param_array.all? { |param| values.call(param) } if values.is_a? Proc
        param_array.all? { |param| values.include?(param) }
      end

      def check_excepts(param_array)
        excepts = @excepts.is_a?(Proc) ? @excepts.call : @excepts
        return true if excepts.nil?
        param_array.none? { |param| excepts.include?(param) }
      end

      def except_message
        options = instance_variable_get(:@option)
        options_key?(:except_message) ? options[:except_message] : message(:except_values)
      end

      def required_for_root_scope?
        @required && @scope.root?
      end
    end
  end
end
