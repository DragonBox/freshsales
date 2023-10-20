# frozen_string_literal: true

## --- BEGIN LICENSE BLOCK ---
# Copyright (c) 2018-present WeWantToKnow AS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
## --- END LICENSE BLOCK ---

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rubocop/rake_task'

require 'logger'
require 'colored'
require 'highline/import'
module UI
  # raised from crash!
  class UICrash < StandardError
  end

  class EPipeIgnorerLogDevice < Logger::LogDevice
    def initialize(logdev)
      @logdev = logdev
    end

    # rubocop:disable HandleExceptions
    def write(message)
      @logdev.write(message)
    rescue Errno::EPIPE
      # ignored
    end
    # rubocop:enable HandleExceptions
  end
  class << self
    def log
      return @log if @log

      $stdout.sync = true

      @log ||= Logger.new(EPipeIgnorerLogDevice.new($stdout))

      @log.formatter = proc do |severity, datetime, _progname, msg|
        "#{format_string(datetime, severity)}#{msg}\n"
      end

      @log
    end

    def verbose?
      false
    end

    def format_string(datetime = Time.now, severity = "")
      timestamp ||= if verbose?
                      '%Y-%m-%d %H:%M:%S.%2N'
                    else
                      '%H:%M:%S'
                    end
      s = []
      s << "#{severity} " if verbose? && severity && !severity.empty?
      s << "[#{datetime.strftime(timestamp)}] " if timestamp
      s.join('')
    end

    def confirm(message)
      verify_interactive!(message)
      agree("#{format_string}#{message.to_s.yellow} (y/n)", true)
    end

    def user_error!(message)
      raise StandardError, message.to_s.red
    end

    def input(message)
      verify_interactive!(message)
      ask("#{format_string}#{message.to_s.yellow}").to_s.strip
    end

    def error(message)
      log.error(message.to_s.red)
    end

    def important(message)
      log.error(message.to_s.yellow)
    end

    def success(message)
      log.error(message.to_s.green)
    end

    def message(message)
      log.info(message.to_s)
    end

    def deprecated(message)
      log.error(message.to_s.bold.blue)
    end

    def command(message)
      log.info("$ #{message}".cyan.underline)
    end

    def interactive?
      interactive = true
      interactive = false if $stdout.isatty == false
      # interactive = false if Helper.ci?
      return interactive
    end

    private

    def verify_interactive!(message)
      return if interactive?
      important(message)
      crash!("Could not retrieve response as the program runs in non-interactive mode")
    end

    def crash!(exception)
      raise UICrash.new, exception.to_s
    end
  end
end

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

class GithubChangelogGenerator
  PATH = '.github_changelog_generator'
  class << self
    def future_release
      s = File.read(PATH)
      s.split("\n").each do |line|
        m = line.match(/future-release=v(.*)/)
        return m[1] if m
      end
      raise "Couldn't find future-release in #{PATH}"
    end

    def future_release=(nextv)
      s = File.read(PATH)
      lines = s.split("\n").map do |line|
        m = line.match(/future-release=v(.*)/)
        if m
          "future-release=v#{nextv}"
        else
          line
        end
      end
      File.write(PATH, lines.join("\n") + "\n")
    end
  end
end

class FreshsalesCode
  PATH = 'lib/freshsales/version.rb'
  class << self
    def version=(version)
      s = File.read(PATH)
      lines = s.split("\n").map do |line|
        m = line.match(/(.*VERSION = ['"]).*(['"].*)/)
        if m
          "#{m[1]}#{version}#{m[2]}"
        else
          line
        end
      end
      File.write(PATH, lines.join("\n") + "\n")
    end
  end
end

require 'English'
def run_command(command, error_message = nil)
  output = `#{command}`
  unless $CHILD_STATUS.success?
    error_message = "Failed to run command '#{command}'" if error_message.nil?
    UI.user_error!(error_message)
  end
  output
end

task :ensure_git_clean do
  branch = run_command('git rev-parse --abbrev-ref HEAD', "Couldn't get current git branch").strip
  UI.user_error!("You are not on 'master' but on '#{branch}'") unless branch == "master"
  output = run_command('git status --porcelain', "Couldn't get git status")
  UI.user_error!("git status not clean:\n#{output}") unless output == ""
end

# ensure ready to prepare a PR
task :prepare_git_pr, [:pr_branch] do |_t, args|
  pr_branch = args['pr_branch']
  raise "Missing pr_branch argument" unless pr_branch
  UI.user_error! "Prepare git PR stopped by user" unless UI.confirm("Creating PR branch #{pr_branch}")
  run_command("git checkout -b #{pr_branch}")
end

desc 'Prepare a release: check repo status, generate changelog, create PR'
task pre_release: 'ensure_git_clean' do
  require 'freshsales/version'
  nextversion = Freshsales::VERSION

  # check not already released
  output = run_command("git tag -l v#{nextversion}").strip
  UI.user_error! "Version '#{nextversion}' already released. Run 'rake bump'" unless output == ''

  gh_future_release = GithubChangelogGenerator.future_release
  UI.user_error! "GithubChangelogGenerator version #{gh_future_release} != #{nextversion}" unless gh_future_release == nextversion

  pr_branch = "release_#{nextversion}"
  Rake::Task["prepare_git_pr"].invoke(pr_branch)

  Rake::Task["changelog"].invoke

  sh('git diff')
  # FIXME: cleanup branch, etc
  UI.user_error! "Pre release stopped by user." unless UI.confirm("CHANGELOG PR for version #{nextversion}. Confirm?")

  msg = "Preparing release for #{nextversion}"
  sh 'git add CHANGELOG.md'
  sh "git commit -m '#{msg}'"
  sh "git push lacostej" # FIXME: hardcoded
  # FIXME: check hub present
  sh "hub pull-request -m '#{msg}'" # requires hub pre-release " -l nochangelog"
  sh 'git checkout master'
  sh "git branch -D #{pr_branch}"
end

desc 'Bump the version number to the version entered interactively; pushes a commit to master'
task bump: 'ensure_git_clean' do
  nextversion = UI.input "Next version will be:"
  UI.user_error! "Bump version stopped by user" unless UI.confirm("Next version will be #{nextversion}. Confirm?")
  FreshsalesCode.version = nextversion
  GithubChangelogGenerator.future_release = nextversion
  sh 'bundle exec rspec'
  sh 'git add .github_changelog_generator lib/freshsales/version.rb Gemfile.lock'
  sh "git commit -m 'Bump version to #{nextversion}'"
  sh 'git push'
end

desc 'Update the changelog, no commit made'
task :changelog do
  puts "Updating changelog #{ENV['CHANGELOG_GITHUB_TOKEN']}"
  sh "github_changelog_generator" if ENV['CHANGELOG_GITHUB_TOKEN']
end

desc 'Run all rspec tests'
task :test_all do
  formatter = "--format progress"
  if ENV["CIRCLECI"]
    Dir.mkdir("/tmp/rspec/")
    formatter += " -r rspec_junit_formatter --format RspecJunitFormatter -o /tmp/rspec/rspec.xml"
    TEST_FILES = `(circleci tests glob "spec/**/*_spec.rb" | circleci tests split --split-by=timings)`.tr!("\n", ' ')
    rspec_args = "#{formatter} #{TEST_FILES}"
  else
    formatter += ' --pattern "./spec/**/*_spec.rb"'
    rspec_args = formatter
  end
  sh "bundle exec rspec #{rspec_args}"
end

task default: %i[rubocop test_all]
