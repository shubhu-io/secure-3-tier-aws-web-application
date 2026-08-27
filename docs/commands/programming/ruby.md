# Ruby

Reference commands for Ruby development. Not part of this project's runtime but useful for web development (Ruby on Rails), automation, and general DevOps.

## Version Check

```bash
ruby --version
gem --version
irb --version      # Interactive Ruby shell
```

## Installation

```bash
# macOS
brew install ruby

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y ruby-full ruby-bundler

# Windows: Use Ruby Installer from rubyinstaller.org

# SDKMAN (optional)
sdk install ruby

# rbenv (version manager, recommended)
# rbenv install 3.3.0
# rbenv global 3.3.0

# rvm (Ruby Version Manager)
# \curl -sSL https://get.rvm.io | bash -s stable --ruby
```

## Hello World

```bash
# Create hello.rb
echo 'puts "Hello, World!"' > hello.rb

# Run
ruby hello.rb

# Irb (interactive)
irb          # Start IRB session
irb --simple-prompt  # Simpler prompt
```

## Installation & Setup

```bash
# Ruby version managers (recommended)
# rbenv: lightweight, no auto-environment modification
# rvm: comprehensive, includes gemset support

# Default Ruby install location:
# macOS: /usr/local/bin/ruby (with brew)
# Ubuntu: /usr/bin/ruby (apt)

# Verify
ruby -v     # Show version
which ruby   # Show binary location

# Set up Bundler (dependency manager)
gem install bundler
```

## Dependency/Package Management

Ruby uses Gem as its package manager, coordinated via Bundler:

```bash
# Install a gem
gem install <gem-name>

# Install specific version
gem install rails --version 7.1.0

# Install gems defined in Gemfile (this project's approach)
bundle install

# Update gems
bundle update

# List installed gems
gem list

# List gems in project
bundle list

# This project doesn't use Ruby directly
# But bundler pattern is: bundle install for Gemfile, npm install for package.json
```

## Build

Ruby is interpreted, no traditional build step:

```bash
# No compile step - Ruby is interpreted

# Popular Ruby frameworks (not used by this project):
# - Ruby on Rails: web applications
# - Sinatra: lightweight web framework
# - Rake: task runner (similar to Makefile)

# This project uses Node.js/TypeScript + Terraform
```

## Run

```bash
# Simple script execution
ruby script.rb

# With arguments
ruby script.rb arg1 arg2

# Rails-specific
rails server      # Start Rails server
rails console     # Start Rails console

# This project doesn't use Ruby runtime
```

## Test

```bash
# Using RSpec (popular Ruby BDD test framework)
# Install: gem install rspec or bundle add rspec-rails

# Run all specs
rspec

# Run specific spec
rspec spec/features/login_spec.rb

# With code coverage
rspec --format progress --format RspecJunitFormatter  # For CI

# Using Minitest (built into Ruby)
ruby -e require 'minitest/unit'  # Simple test run

# This project doesn't use Ruby testing
```

## Lint

```bash
# Using RuboCop (standard Ruby linter)
rubocop              # Lint all Ruby files
rubocop -a           # Auto-correct offenses

# Config via .rubocop.yml
# This project doesn't use Ruby linting (uses ESLint/Prettier for JS)
```

## Format

```bash
# Using rubocop for formatting (also lints)
rubocop              # Show offenses only
rubocop -a           # Auto-correct and format

# This project doesn't use Ruby formatting (uses Prettier for JS/TS)
```

## Clean

```bash
# Remove Gem bundle
rm -rf .bundle/

# Remove Gemfile.lock
rm -f Gemfile.lock

# Clean up installed gems (keep only those in Gemfile)
bundle clean

# Remove .irbrc and other config
rm -rf ~/.irb*

# This project doesn't use Ruby
```

## Production Build

```bash
# Ruby on Rails production:
# - Deploy via Capistrano, Docker, or platform services
# - Use Puma web server
# - Configure Rails.env=production
# - Set up database migrations

# No traditional "build" step
# Ruby is interpreted, deployed via:
# - Docker containers (this project's approach)
# - Platform-as-a-Service (Heroku, Render, etc.)
# - Traditional cloud deployment

# This project uses Docker for consistent deployment
```

## Troubleshooting

```bash
# Common issues
# "ruby: command not found" - install Ruby or use version manager
# "bundle: command not found" - run gem install bundler
# "could not find gem 'x'" - run bundle install

# Version manager issues
# rbenv rehash     # After gem install
# rvm use 3.3.0    # Switch Ruby version

# Debugging
ruby -c script.rb    # Check Ruby syntax without running
ruby -e "puts $!"  # Show last error

# Version management
rbenv versions     # List installed Ruby versions
rbenv global       # Show current global version
```