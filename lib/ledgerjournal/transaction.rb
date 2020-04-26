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
        date: Date.strptime(xml.xpath('date').text, '%Y/%m/%d'),
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

      lines += metadata.to_a.sort { |a, b| a[0].casecmp(b[0]) }.collect { |m| "    ; #{m[0]}: #{m[1]}" } unless metadata.empty?

      lines += postings.map { |posting| posting.to_s.lines.map { |line| '    ' + line }.join }

      return lines.join("\n") + "\n"
    end

    # @param [String] account
    # @return [Ledger::Posting]
    def posting_for_account(account)
      postings.select { |posting| posting.account == account }.first
    end

    protected

    def all_fields
      instance_variables.map { |variable| instance_variable_get(variable) }
    end
  end
end
