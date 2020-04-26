# frozen_string_literal: true

require 'date'
require 'bigdecimal'

module Ledger
  # @attr [String] account
  # @attr [String] currency
  # @attr [BigDecimal] amount
  # @attr [BigDecimal] balance_assignment if a balance_assignment is set, ledger-cli checks the balance of the account after this posting
  # @attr [Hash<String, String>] metadata
  class Posting
    attr_accessor :account, :currency, :amount, :balance_assignment, :metadata

    def initialize(account:, currency:, amount:, balance_assignment: nil, metadata: {})
      @account = account
      @currency = currency
      @amount = amount
      @balance_assignment = balance_assignment
      @metadata = metadata
    end

    def self.parse_xml(xml)
      balance_assignment = nil
      currency = xml.xpath('post-amount/amount/commodity/symbol').text
      if (xml_balance = xml.xpath('balance-assignment').first)
        balance_currency = xml_balance.xpath('commodity/symbol').text
        raise Error, "Posting currency #{currency} doesn't match assignment currency #{balance_currency}" if currency != balance_currency

        balance_assignment = Ledger.defaults.parse_amount(xml_balance.xpath('quantity').text)
      end
      Posting.new(
        account: xml.xpath('account/name').text,
        currency: currency,
        amount: Ledger.defaults.parse_amount(xml.xpath('post-amount/amount/quantity').text),
        balance_assignment: balance_assignment,
        metadata: Hash[xml.xpath('metadata/value').collect { |m| [m['key'], m.xpath('string').text] }]
      )
    end

    def ==(other)
      self.class == other.class && all_fields == other.all_fields
    end

    def to_s
      posting_line = "#{account}   "
      posting_line += "#{currency} #{Ledger.defaults.format(amount)}".rjust(48 - posting_line.length, ' ')
      posting_line += " = #{currency} #{Ledger.defaults.format(balance_assignment)}" if balance_assignment
      lines = [posting_line]
      lines += metadata.to_a.collect { |m| "; #{m[0]}: #{m[1]}" } unless metadata.empty?
      return lines.join("\n")
    end

    protected

    def all_fields
      instance_variables.map { |variable| instance_variable_get variable }
    end
  end
end
