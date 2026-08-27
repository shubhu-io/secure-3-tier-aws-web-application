# PHP

Reference commands for PHP development. Not part of this project's runtime but useful for web development, legacy systems, and general DevOps.

## Version Check

```bash
php --version
php -m                # List PHP modules
```

## Installation

```bash
# macOS
brew install php        # installs with default modules
brew install php@8.2  # Specific version
brew install php        # with extensions: brew install php imap

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y php8.2 php8.2-cli php8.2-mysql

# With popular extensions
sudo apt-get install -y php8.2-cli php8.2-mbstring php8.2-xml php8.2-zip

# Windows: Download from php.net or use XAMPP/WAMP

# Verify PHP-FPM
php-fpm8.2 --version
```

## Hello World

```bash
# Create hello.php
echo '<?php echo "Hello, World!";' > hello.php

# Run from command line
php hello.php

# Using built-in web server (development)
php -S localhost:8000

# This project doesn't use PHP runtime
```

## Dependency/Package Management

PHP uses Composer as its package manager:

```bash
# Install Composer (if not already installed)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Or download directly
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install dependencies
composer install

# Install a specific package
composer require <package>

# Install with version constraint
composer require "vendor/package:^5.0"

# Remove a package
composer remove <package>

# Update all packages
composer update

# Dump autoload (after adding/removing packages)
composer dump-autoload

# This project doesn't use PHP dependencies
```

## Build

PHP is interpreted, but you can optimize:

```bash
# OpCache optimization (usually configured in php.ini)
# No explicit build step

# For HHVM (HipHop Virtual Machine - legacy)
# hhvm hello.php

# This project doesn't use PHP build steps
```

## Run

```bash
# Simple script execution
php script.php

# With arguments
php script.php arg1 arg2

# Web server (development)
php -S localhost:8000

# Framework server (Laravel, etc.)
# php artisan serve  (Laravel)

# This project doesn't use PHP runtime
```

## Test

```bash
# Using PHPUnit (standard PHP test framework)
# Install: composer require --dev phpunit/phpunit

# Run all tests
./vendor/bin/phpunit

# Run specific test
./vendor/bin/phpunit --filter testName

# With coverage
./vendor/bin/phpunit --coverage-html coverage/

# This project uses Jest for JavaScript testing, not PHP testing
```

## Lint

```bash
# Using PHP CodeSniffer (code style checking)
composer global require phpcodesniffer
phpcs script.php

# Using PHP CS Fixer (auto-fix)
composer global require friendsofphp/php-cs-fixer
php-cs-fixer fix script.php

# This project doesn't use PHP linting (uses ESLint/Prettier for JS)
```

## Format

```bash
# Using PHP CS Fixer
php-cs-fixer fix --rules=@PSR12 script.php

# Using pretty adaptive style
php-cs-fixer fix --rules=@PSR12 --diff-matrix script.php

# Using native formatting (basic)
php -r "echo 'formatting';"

# This project uses Prettier for JS/TS formatting
```

## Clean

```bash
# Remove vendor directory (reinstall deps)
rm -rf vendor/

# Remove composer.lock
rm -f composer.lock

# Remove autoload files
rm -f autoload.php

# Completely reset Composer
rm -rf vendor/ composer.lock autoload.php
composer install

# This project doesn't use PHP
```

## Production Build

```bash
# PHP production typically involves:
# - OpCache enabled in php.ini
# - FPM (FastCGI Process Manager)
# - Proper php.ini production settings

# No traditional "build" step for PHP
# Deploy via:
# - Docker containers
# - Direct server deployment
# - Platform.sh, Heroku, etc.

# This project uses Docker for PHP-like containerized deployment
```

## Troubleshooting

```bash
# Common issues
# "php: command not found" - install PHP, add to PATH
# "Class 'Foo' not found" - composer install missing dependencies
# "Maximum execution time exceeded" - adjust php.ini max_execution_time
# "Allowed memory size exhausted" - adjust php.ini memory_limit

# Debugging
php -v                      # Verify PHP version
php -m                     # List all modules/extensions
php --ini                  # Show php.ini location and settings

# Common extensions
# extension=gd.so
# extension=mysqli.so
# extension=mbstring.so

# Composer issues
composer diagnose        # Check common issues
composer self-update     # Update composer to latest version
```