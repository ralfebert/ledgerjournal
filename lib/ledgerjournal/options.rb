# frozen_string_literal: true

module Ledger
  # Options for interaction with ledger-cli
  class Options
    attr_reader :date_format
    attr_reader :decimal_comma

    # @param [String] date_format like '%Y/%m/%d' to pass to ledger-cli
    # @param [Boolean] decimal_comma pass true to use a comma as decimal separator, otherwise a dot is used
    def initialize(date_format:, decimal_comma:)
      @date_format = date_format
      @decimal_comma = decimal_comma
    end

    # Returns default options by locale. Currently supported are :en or :de.
    # @param [Symbol] locale as symbol
    # @return [Ledger::Options]
    def self.for_locale(locale)
      case locale.to_sym
      when :en
        Options.new(date_format: '%Y/%m/%d', decimal_comma: false)
      when :de
        Options.new(date_format: '%d.%m.%Y', decimal_comma: true)
      else
        raise Error, "Unknown locale for ledger options: #{locale}, supported are :en, :de"
      end
    end

    # @param [String] string decimal amount as String (like '12.34')
    # @return [BigDecimal] the given string as BigDecimal, parsed according the decimal_comma setting
    def parse_amount(string)
      BigDecimal(@decimal_comma ? string.gsub('.', '').gsub(',', '.') : string)
    end

    # Formats the given value as String
    # @param [Date, BigDecimal] value to parse
    # @return [String] string representation according to the options
    def format(value)
      if value.instance_of? Date
        return value.strftime(@date_format)
      elsif value.instance_of? BigDecimal
        str = '%.2f' % value
        str.gsub!('.', ',') if @decimal_comma
        return str
      else
        raise Error, "Unknown value type #{value.class}"
      end
    end

    # Runs ledger-cli
    # @param [String] args command line arguments to pass
    # @param [String] stdin stdin text to pass
    # @return [String] stdout result of calling ledger
    def run(args, stdin: nil)
      output = String.new
      error = String.new
      begin
        Open4.spawn("ledger #{cmdline_options} #{args}", stdin: stdin, stdout: output, stderr: error)
      rescue StandardError => e
        raise Error, "#{e}: #{error}"
      end
      return output
    end

    private

    def cmdline_options
      args = ['--args-only', "--date-format #{@date_format}", "--input-date-format #{@date_format}"]
      args << '--decimal-comma' if @decimal_comma
      return args.join(' ')
    end
  end

  @defaults = Options.for_locale(:en)

  class <<self
    # @attr [Ledger::Options] defaults options to use when interacting with ledger-cli, by default settings for locale :en are used
    attr_accessor :defaults
  end
end
