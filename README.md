# Minbox

A minimal SMTP server written in ruby. `Minbox` offers a command line
interface and is useful for end-to-end test suites or as a standalone SMTP server
for development.

`Minbox` is capable of publishing email messages to `stdout`, or the `file`
system.

The `file` system publisher will write all emails to `./tmp` of the
directory where you run minbox from. Each file is named with the format
of `<timestamp>.eml`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'minbox'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install minbox

## Usage

```bash
モ minbox
minbox commands:
  minbox client <HOST> <PORT>  # SMTP client
  minbox help [COMMAND]        # Describe available commands or one specific command
  minbox server <HOST> <PORT>  # SMTP server
  minbox version               # Display the current version
```

To start an SMTP server run:

```bash
モ minbox server localhost 8080
D, [2019-03-12T17:08:19.671765 #36618] DEBUG -- : Starting server on port 8080...
D, [2019-03-12T17:08:19.679380 #36618] DEBUG -- : Server started!
```

You can use the `--output` option to configure the different types of
publishers to publish to. The following example will publish emails to
`stdout`, and `file` system.

```bash
モ minbox server localhost 8080 --output=stdout file
D, [2019-03-12T17:16:03.564426 #36907] DEBUG -- : Starting server on port 8080...
D, [2019-03-12T17:16:03.565964 #36907] DEBUG -- : Server started!
```

To send an example email:

```bash
モ minbox client localhost 8080
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/xlgmokha/minbox.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
