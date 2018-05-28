# Simple Xspec Wrapper

A simple wrapper around Xspec to run, independently, all .xspec files in a folder hierarchy.

It assumes XSLT.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple-xspec-wrapper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple-xspec-wrapper

## Usage

    $ xspec /path/to/xspec

It will run all `.xspec` files under the path you passed in.

If you use Saxon PE or EE, then drop run the command from the directory your `saxon-license.lic` file is in and it'll pick that up and look in the `$SAXON_HOME` environment variable to find your copy of Saxon PE/EE (defaulting to `/opt/saxon` if that isn't set).

    $ SAXON_HOME=/path/to/saxon_dir xspec /path/to/specs

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fidothe/simple-xspec-wrapper. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT). This gem bundles XSpec, which is released under the MIT License. A few parts of the XSpec codebase are released under the [Mozilla Public License](http://www.mozilla.org/MPL/).

## Code of Conduct

Everyone interacting in the Simple Xspec Wrapper project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fidothe/simple-xspec-wrapper/blob/master/CODE_OF_CONDUCT.md).
