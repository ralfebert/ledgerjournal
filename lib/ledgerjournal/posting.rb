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
      if xml_balance = xml.xpath('balance-assignment').first
        balance_currency = xml_balance.xpath('commodity/symbol').text
        raise Error.new("Posting currency #{currency} doesn't match assignment currency #{balance_currency}") if currency != balance_currency
        balance_assignment = Ledger.defaults.parse_amount(xml_balance.xpath('quantity').text)
      end
      Posting.new(
        account: xml.xpath('account/name').text,
        currency: currency,
        amount: Ledger.defaults.parse_amount(xml.xpath('post-amount/amount/quantity').text),
        balance_assignment: balance_assignment,
        metadata: Hash[xml.xpath("metadata/value").collect {|m| [m['key'], m.xpath("string").text]}]
      )
    end
    
    def ==(other)
      self.class == other.class && self.all_fields == other.all_fields
    end
    
    def to_s
      posting_line = "#{self.account}      #{self.currency} #{Ledger.defaults.format(self.amount)}"
      if self.balance_assignment
        posting_line += " = #{self.currency} #{Ledger.defaults.format(self.balance_assignment)}"
      end
      lines = [posting_line]
      unless self.metadata.empty?
        lines += metadata.to_a.sort {|a,b| a[0].casecmp(b[0]) }.collect{|m| "; #{m[0]}: #{m[1]}" }
      end
      return lines.join("\n")
    end
    
    protected
    def all_fields
      self.instance_variables.map { |variable| self.instance_variable_get variable }
    end
    
  end

end
