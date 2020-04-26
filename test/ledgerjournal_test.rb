require "test_helper"

class LedgerTest < Minitest::Test

  def setup
    Ledger.defaults = Ledger::Options.for_locale(:en)
  end

  def fixture_path(name)
    File.join(File.dirname(__FILE__), name)
  end
  
  def example_journal_en
    journal = Ledger::Journal.new()

    journal.transactions << Ledger::Transaction.new(
      date: Date.new(2010, 12, 1),
      state: :cleared,
      payee: 'Checking balance',
      postings: [
        Ledger::Posting.new(account: "Assets:Checking", currency: "$", amount: BigDecimal('1000')),
        Ledger::Posting.new(account: "Equity:Opening Balances", currency: "$", amount: BigDecimal('-1000'))
      ]
    )

    journal.transactions << Ledger::Transaction.new(
      date: Date.new(2010, 12, 20),
      state: :pending,
      payee: 'Organic Co-op',
      postings: [
        Ledger::Posting.new(account: "Expenses:Food:Groceries", currency: "$", amount: BigDecimal('37.50')),
        Ledger::Posting.new(account: "Assets:Checking", currency: "$", amount: BigDecimal('-37.50'), balance_assignment: BigDecimal('962.50'))
      ]
    )

    return journal
  end

  def example_journal_de
    journal = Ledger::Journal.new()

    journal.transactions << Ledger::Transaction.new(
      date: Date.new(2020, 1, 2),
      state: :cleared,
      payee: 'Example Payee',
      metadata: { "Foo" => "Bar", "Description" => "Example Transaction" },
      postings: [
        Ledger::Posting.new(account: "Expenses:Unknown", currency: "EUR", amount: BigDecimal('1234.56'), metadata: { "Foo" => "Bar", "Description" => "Example Posting" }),
        Ledger::Posting.new(account: "Assets:Checking", currency: "EUR", amount: BigDecimal('-1234.56'))
      ]
    )

    return journal
  end

  def test_create_journal_en
    assert_equal File.read(fixture_path("example_journal_en.txt")), example_journal_en.to_s
  end

  def test_parse_journal_en
    parsed_journal = Ledger::Journal.new(path: fixture_path("example_journal_en.txt"))
    parsed_journal.transactions.each do |tx|
      puts tx.date, tx.payee
    end
    assert_equal example_journal_en, parsed_journal
  end

  def test_create_journal_de
    Ledger.defaults = Ledger::Options.for_locale(:de)
    assert_equal File.read(fixture_path("example_journal_de.txt")), example_journal_de.to_s
  end

  def test_parse_journal_de
    Ledger.defaults = Ledger::Options.for_locale(:de)
    parsed_journal = Ledger::Journal.new(path: fixture_path("example_journal_de.txt"))
    assert_equal example_journal_de, parsed_journal
  end

  def test_transactions_with_account
    journal = example_journal_en
    assert_equal [journal.transactions[0]], journal.transactions_with_account("Equity:Opening Balances")
  end

  def test_posting_for_account
    journal = example_journal_en
    tx = journal.transactions[0]
    assert_equal tx.postings[0], tx.posting_for_account("Assets:Checking")
  end

  def test_journal_with_ledger_args
    assert_equal ["Organic Co-op"], Ledger::Journal.new(path: fixture_path("example_journal_en.txt"), ledger_args: "-p 2010/12/20").transactions.map(&:payee)
  end

end