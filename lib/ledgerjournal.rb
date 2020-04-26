# frozen_string_literal: true

require 'ledgerjournal/version'
require 'ledgerjournal/options'
require 'ledgerjournal/journal'
require 'ledgerjournal/transaction'
require 'ledgerjournal/posting'

# Ledger provides classes to read and write ledger accounting files.
module Ledger
  # Error class for errors handling ledger files
  class Error < StandardError; end
end
