# frozen_string_literal: true

require 'date'

module Ledger
  # @attr [Date] date
  # @attr [Symbol] state state of transaction, can be :cleared or :pending
  # @attr [String] payee
  # @attr [Hash<String, String>] metadata
  # @attr [Array<Ledger::Posting>] postings
  class Transaction
    attr_accessor :date, :state, :payee, :metadata, :postings

    def initialize(date:, state: :cleared, payee:, metadata: {}, postings:)
      @date = date
      @state = state
      @payee = payee
      @metadata = metadata
      @postings = postings
    end

    def self.parse_xml(xml)
      Transaction.new(
        date: Date.strptime(xml.xpath('date').text, Ledger.defaults.date_format),
        payee: xml.xpath('payee').text,
        state: xml['state'].to_sym,
        metadata: Hash[xml.xpath('metadata/value').collect { |m| [m['key'], m.xpath('string').text] }],
        postings: xml.xpath('postings/posting').map { |posting_xml| Posting.parse_xml(posting_xml) }
      )
    end

    def ==(other)
      self.class == other.class && all_fields == other.all_fields
    end

    def to_s
      date_str = Ledger.defaults.format(date)
      states = { pending: '!', cleared: '*' }
      lines = ["#{date_str} #{states[state]} #{payee}"]

      lines += metadata.to_a.collect { |m| "    ; #{m[0]}: #{m[1]}" } unless metadata.empty?

      lines += postings.map { |posting| posting.to_s.lines.map { |line| '    ' + line }.join }

      return lines.join("\n")
    end

    # @param [String, Array<String>] accounts name(s)
    # @return [Ledger::Posting] Returns the first posting that matches one of the given account names
    def posting_for_account(accounts)
      accounts = [accounts] unless accounts.is_a?(Enumerable)
      accounts.each do |account|
        postings.each do |posting|
          return posting if account == posting.account
        end
      end
      return nil
    end

    protected

    def all_fields
      instance_variables.map { |variable| instance_variable_get(variable) }
    end
  end
end
