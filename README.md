# ledgerjournal

[![Gem Version](https://badge.fury.io/rb/ledgerjournal.svg)](https://badge.fury.io/rb/ledgerjournal)
[![Build Status](https://travis-ci.org/ralfebert/ledgerjournal.svg?branch=master)](https://travis-ci.org/github/ralfebert/ledgerjournal)

ledgerjournal is a Ruby gem to read and write [ledger](https://www.ledger-cli.org/) accounting files.
For parsing, it uses the [ledger xml command](https://www.ledger-cli.org/3.0/doc/ledger3.html#The-xml-command). For outputting, it formats the ledger data as String in Ruby.
The ledger binary needs to be installed to parse and pretty-print.

## Usage

Parsing a leger file: 

```ruby
journal = Ledger::Journal.new(path: "example_journal_en.txt")
journal.transactions.each do |tx|
  puts tx.date, tx.payee
end
```

Creating a ledger:

```ruby
journal = Ledger::Journal.new(path: "example_journal_en.txt")

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

puts(journal.to_s)
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ledgerjournal'
```

Or install it yourself as:

    $ gem install ledgerjournal

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ralfebert/ledgerjournal.

## License

ledgerjournal is released under the MIT License. See LICENSE.md.
