# frozen_string_literal: true

require 'shellwords'
require 'nokogiri'
require 'open4'
require 'set'

module Ledger
  # Represents a ledger journal
  # @see https://www.ledger-cli.org/3.0/doc/ledger3.html#Journal-Format
  class Journal
    # @return [Array<Ledger::Transaction>] list of transactions in journal
    attr_accessor :transactions
    # @return [String] path path to ledger file
    attr_reader :path

    # Creates a new ledger journal or loads transactions from a ledger journal file.
    # @param [String] path path to a ledger journal to load
    # @param [String] ledger_args when loading from a path, you can pass in arguments to the ledger command (for example to filter transactions)
    def initialize(path: nil, ledger_args: nil)
      @transactions = []
      if path
        @path = path
        raise Error, "#{@path} not found" unless File.exist?(@path)

        read_ledger(ledger_args: ["-f #{@path.shellescape}", ledger_args].compact.join(' '))
      end
    end

    # @param [Ledger::Journal] other
    # @return [Boolean] true if the other journal contains equal transactions
    def ==(other)
      transactions == other.transactions
    end

    # @return [String] returns the transactions in the journal formatted as string
    # @param [Boolean] pretty_print calls ledger to format the journal if true
    def to_s(pretty_print: true)
      str = transactions.map(&:to_s).join("\n\n")
      if pretty_print
        begin
          str = Ledger.defaults.run('-f - print', stdin: str)
          str = str.lines.map(&:rstrip).join("\n") + "\n"
        rescue StandardError => e
          # return an unformatted string if an error occurs
          puts "Couldn't format transaction log: #{e}"
        end
      end
      return str
    end

    # If the journal was opened from a file, save/overwrite the file with the transactions from this journal.
    def save!
      raise Error, 'Journal was not read from path, cannot save' unless @path

      File.write(@path, to_s)
    end

    # returns all transactions that have a posting for one of the given accounts
    # @param [String, Array<String>, Set<String>] account account name(s)
    def transactions_with_account(account)
      accounts = account.is_a?(Enumerable) ? Set.new(account) : Set[account]
      @transactions.select { |tx| accounts.intersect?(Set.new(tx.postings.map(&:account))) }
    end

    private

    def read_ledger(ledger_args: '')
      xml_result = Ledger.defaults.run(ledger_args + ' xml')
      xml = Nokogiri::XML(xml_result)
      @transactions = xml.xpath('ledger/transactions/transaction').map { |tx_xml| Transaction.parse_xml(tx_xml) }
    end
  end
end
