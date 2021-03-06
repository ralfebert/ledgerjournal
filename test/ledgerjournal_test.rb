# frozen_string_literal: true

require 'test_helper'

class LedgerTest < Minitest::Test
  def setup
    Ledger.defaults = Ledger::Options.for_locale(:en)
  end

  def fixture_path(name)
    File.join(File.dirname(__FILE__), name)
  end

  def example_journal(name)
    Ledger::Journal.new(path: fixture_path(name))
  end

  def example_journal_en
    journal = Ledger::Journal.new

    journal.transactions << Ledger::Transaction.new(
      date: Date.new(2010, 12, 1),
      state: :cleared,
      payee: 'Checking balance',
      postings: [
        Ledger::Posting.new(account: 'Assets:Checking', currency: '$', amount: BigDecimal('1000')),
        Ledger::Posting.new(account: 'Equity:Opening Balances', currency: '$', amount: BigDecimal('-1000'))
      ]
    )

    journal.transactions << Ledger::Transaction.new(
      date: Date.new(2010, 12, 20),
      state: :pending,
      payee: 'Organic Co-op',
      postings: [
        Ledger::Posting.new(account: 'Expenses:Food:Groceries', currency: '$', amount: BigDecimal('37.50')),
        Ledger::Posting.new(account: 'Assets:Checking', currency: '$', amount: BigDecimal('-37.50'), balance_assignment: BigDecimal('962.50'))
      ]
    )

    return journal
  end

  def example_journal_de
    journal = Ledger::Journal.new

    journal.transactions << Ledger::Transaction.new(
      date: Date.new(2020, 1, 2),
      state: :cleared,
      payee: 'Example Payee',
      metadata: { 'Foo' => 'Bar', 'Description' => 'Example Transaction' },
      postings: [
        Ledger::Posting.new(account: 'Expenses:Unknown', currency: 'EUR', amount: BigDecimal('1234.56'), metadata: { 'Foo' => 'Bar', 'Description' => 'Example Posting' }),
        Ledger::Posting.new(account: 'Assets:Checking', currency: 'EUR', amount: BigDecimal('-1234.56'))
      ]
    )

    return journal
  end

  def test_create_journal_en
    assert_equal File.read(fixture_path('example_journal_en.txt')), example_journal_en.to_s
  end

  def test_create_journal_en_without_prettyprint
    assert_equal File.read(fixture_path('example_journal_en_unformatted.txt')), example_journal_en.to_s(pretty_print: false)
  end

  def test_create_journal_invalid
    journal = Ledger::Journal.new

    journal.transactions << Ledger::Transaction.new(
      date: Date.new(2020, 1, 2),
      payee: 'Example Payee',
      postings: [
        Ledger::Posting.new(account: 'Expenses:Unknown', currency: 'EUR', amount: BigDecimal(10)),
        Ledger::Posting.new(account: 'Assets:Checking', currency: 'EUR', amount: BigDecimal(-11))
      ]
    )

    assert_equal File.read(fixture_path('example_journal_en_invalid.txt')), journal.to_s
  end

  def test_append
    Tempfile.create('ledger') do |tmpfile|
      FileUtils.cp(fixture_path('example_journal_en.txt'), tmpfile.path)
      journal = Ledger::Journal.new(path: tmpfile.path)
      journal.transactions << Ledger::Transaction.new(
        date: Date.new(2020, 1, 2),
        payee: 'Another Payee',
        postings: [
          Ledger::Posting.new(account: 'Expenses:Unknown', currency: 'EUR', amount: BigDecimal(10)),
          Ledger::Posting.new(account: 'Assets:Checking', currency: 'EUR', amount: BigDecimal(-10))
        ]
      )
      journal.save!
      assert_equal(File.read(fixture_path('example_journal_en_appended.txt')), File.read(tmpfile))
    end
  end

  def test_parse_journal_en
    parsed_journal = example_journal('example_journal_en.txt')
    parsed_journal.transactions.each do |tx|
      puts tx.date, tx.payee
    end
    assert_equal example_journal_en, parsed_journal
  end

  def test_create_journal_de
    Ledger.defaults = Ledger::Options.for_locale(:de)
    assert_equal File.read(fixture_path('example_journal_de.txt')), example_journal_de.to_s
  end

  def test_parse_journal_de
    Ledger.defaults = Ledger::Options.for_locale(:de)
    parsed_journal = example_journal('example_journal_de.txt')
    assert_equal example_journal_de, parsed_journal
  end

  def test_transactions_with_account
    journal = example_journal('example_many_postings.txt')
    assert_equal ['Example'], journal.transactions_with_account('Expenses:Example1').map(&:payee)
    assert_equal ['Example'], journal.transactions_with_account(['Expenses:Example1', 'Expenses:Example2']).map(&:payee)
    assert_equal %w[Example Bar], journal.transactions_with_account(['Expenses:Example1', 'Expenses:Bar2']).map(&:payee)
    assert_equal %w[Example Bar], journal.transactions_with_account(Set['Expenses:Example1', 'Expenses:Bar2']).map(&:payee)
    assert_equal [], journal.transactions_with_account(['DoesntExist']).map(&:payee)
  end

  def test_posting_for_account
    journal = example_journal('example_many_postings.txt')
    tx = journal.transactions[0]
    assert_equal tx.postings[1], tx.posting_for_account('Expenses:Example2')
    assert_equal tx.postings[1], tx.posting_for_account(['Expenses:Example2', 'Expenses:Example3'])
    assert_equal tx.postings[1], tx.posting_for_account(Set['Expenses:Example2', 'Expenses:Example3'])
    assert_equal tx.postings[2], tx.posting_for_account(['Expenses:Example3', 'Expenses:Example2'])
    assert_nil tx.posting_for_account('DoesntExist')
  end

  def test_journal_with_ledger_args
    assert_equal ['Organic Co-op'], Ledger::Journal.new(path: fixture_path('example_journal_en.txt'), ledger_args: '-p 2010/12/20').transactions.map(&:payee)
  end

  def test_run_ledger_output
    assert_match(/accounting/i, Ledger.defaults.run('--version'))
  end

  def test_run_ledger_error
    error = assert_raises Ledger::Error do
      Ledger.defaults.run('--doesntexist')
    end
    assert_match(/illegal option/i, error.message)
  end

  def test_format_values_en
    options = Ledger::Options.for_locale(:en)
    assert_equal '1234.56', options.format(BigDecimal('1234.56'))
    assert_equal '2020/03/04', options.format(Date.new(2020, 3, 4))
    assert_equal BigDecimal('1234.56'), options.parse_amount('1234.56')
  end

  def test_format_values_de
    options = Ledger::Options.for_locale(:de)
    assert_equal '1234,56', options.format(BigDecimal('1234.56'))
    assert_equal '04.03.2020', options.format(Date.new(2020, 3, 4))
    assert_equal BigDecimal('1234.56'), options.parse_amount('1234,56')
  end

  def test_posting_equals
    p1 = Ledger::Posting.new(account: 'Assets:Checking', currency: 'EUR', amount: BigDecimal('-1234.56'))
    p2 = Ledger::Posting.new(account: 'Assets:Checking', currency: 'EUR', amount: BigDecimal('-1234.56'))
    p3 = Ledger::Posting.new(account: 'Assets:Checking', currency: 'EUR', amount: BigDecimal('-1234.57'))
    assert_equal p1, p2
    assert !p1.equal?(p3)
  end
end
