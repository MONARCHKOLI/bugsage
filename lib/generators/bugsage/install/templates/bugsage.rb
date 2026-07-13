# frozen_string_literal: true

# BugSage — Rails installation
#
# Quick start (zero-config):
#   1. Add to Gemfile:  gem "bugsage"
#   2. Run:             bundle install
#   3. Run:             bin/rails server
#   4. Trigger an error in development to see the BugSage error page
#   5. Visit:           http://localhost:3000/bugsage
#
# Optional:
#   - bundle exec rails generate bugsage:install   (commented initializer)
#   - export OPENAI_API_KEY=sk-...                 (auto-enables OpenAI)
#   - export CURSOR_API_KEY=crsr_...               (auto-enables Cursor)
#   - export BUGSAGE_ENABLED_ENVIRONMENTS=development,test,staging
#
# BugSage auto-wires middleware, /bugsage, and error pages via Bugsage::Railtie.
# You do not need to edit config/routes.rb or add middleware manually.
#
# See Bugsage::Installation for the full step list, or run:
#   bundle exec bugsage install
