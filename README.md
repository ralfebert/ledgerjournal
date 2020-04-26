# ledgerjournal

[![Gem Version](https://badge.fury.io/rb/ledgerjournal.svg)](https://badge.fury.io/rb/ledgerjournal)
[![Build Status](https://travis-ci.org/ralfebert/ledgerjournal.svg?branch=master)](https://travis-ci.org/github/ralfebert/ledgerjournal)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/gems/ledgerjournal/)

ledgerjournal is a Ruby gem to read and write [ledger](https://www.ledger-cli.org/) accounting files.
For parsing, it uses the [ledger xml command](https://www.ledger-cli.org/3.0/doc/ledger3.html#The-xml-command). For outputting, it formats the ledger data as String in Ruby.
The ledger binary needs to be installed to parse and pretty-print.

## Usage

Parsing a ledger journal file: 

```ruby
journal = Ledger::Journal.new(path: "example_journal.dat")
journal.transactions.each do |tx|
  puts tx.date, tx.payee
end
```

Creating a ledger file from scratch:

```ruby
journal = Ledger::Journal.new()

journal.transactions << Ledger::Transaction.new(
  date: Date.new(2020, 1, 2),
  payee: 'Example Payee',
  metadata: { "Foo" => "Bar", "Description" => "Example Transaction" },
  postings: [
    Ledger::Posting.new(account: "Expenses:Unknown", currency: "EUR", amount: BigDecimal('1234.56'), metadata: { "Foo" => "Bar", "Description" => "Example Posting" }),
    Ledger::Posting.new(account: "Assets:Checking", currency: "EUR", amount: BigDecimal('-1234.56'))
  ]
)

puts(journal.to_s)
```

Appending to a ledger journal: 

```ruby
journal = Ledger::Journal.new(path: "example_journal.dat")
journal.transactions << Ledger::Transaction.new(
  date: Date.new(2020, 1, 2),
  payee: 'Example Payee',
  postings: [
    Ledger::Posting.new(account: "Expenses:Unknown", currency: "EUR", amount: BigDecimal('1234.56')),
    Ledger::Posting.new(account: "Assets:Checking", currency: "EUR", amount: BigDecimal('-1234.56'))
  ]
)
journal.save!
```

Running ledger commands:

```ruby
puts Ledger.defaults.run('--version')
```

### Locale-specific settings

By default ledgerjournal expectes the ledger default date format '%Y/%m/%d' and amounts with decimal point (1234.56). This is configurable:

```ruby
Ledger.defaults = Options.new(date_format: '%d.%m.%Y', decimal_comma: true)
```

or:

```ruby
Ledger.defaults = Ledger::Options.for_locale(:de)
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
