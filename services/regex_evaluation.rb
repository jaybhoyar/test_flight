# frozen_string_literal: true

class RegexEvaluation
  attr_reader :regex, :timeout
  def initialize(regex, timeout = 1)
    @regex = parse_regex(regex)
    @timeout = timeout
  end

  def match(string)
    raise InvalidRegex if !regex

    execute_regex(string)
  end

  class InvalidRegex < StandardError
    def message
      "provided regex is invalid"
    end
  end

  private

    def parse_regex(string)
      supported_options = /[imx]*/
      delimiters = {
        "%r{" => "}",
        "/" => "/"
      }
      delim_start, delim_end = delimiters.detect { |key, _| string.starts_with? key }
      return unless delim_start

      match = string.match(/\A#{delim_start}(?<expression>.*)#{delim_end}(?<options>#{supported_options})\z/u)
      return unless match

      expression = match[:expression].gsub("\\/", "/")
      expression = expression.gsub(%r{\A#{delim_start}|#{delim_end}\z}, "")
      options = match[:options]
      args = 0
      if options
        args = args | Regexp::IGNORECASE if options.include?("i")
        args = args | Regexp::EXTENDED if options.include?("x")
        args = args | Regexp::MULTILINE if options.include?("m")
      end

      Regexp.new(expression, args)
    end

    def execute_regex(string)
      Timeout::timeout(timeout) do
        string.match(regex)
      end
    end
end
