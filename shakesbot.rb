#!/usr/bin/env ruby1.8
# who nathaniel k smith
# what shakesbot.rb
# why perform shakespeare plays from MIT on twitter
# when april 2010
# where http://chiptheglasses.com

require 'rubygems'
require 'nokogiri'
require 'twitter_oauth'

require 'optparse'
require 'ostruct'
require 'pp'

require 'shakescfg'

class Tweeter
    def initialize()
        @client = TwitterOAuth::Client.new(
            :consumer_key    => Config::CONSUMER_KEY,
            :consumer_secret => Config::CONSUMER_SECRET,
            :token           => Config::TOKEN,
            :secret          => Config::SECRET
        )
    end

    # return an array of 140 char or less strings
    def self.break_up(string)
        return [string] if string.length < 140

        broken_up = []
        while string.length > 140
            broken_up.push(string[0,139])
            string = string[0,139]
        end

        broken_up
    end

    def tweet(msg)
        @client.update(msg)
    end
end

class Play
    def initialize(parsed_html)
        @title   = parsed_html.css('td.play').first.content
        @tweeter = Tweeter.new()
        @anchors = parsed_html.css("a[name!='']") # ignore two irrelevant anchors
    end

    # Tweet each line, sleeping for interval seconds in between
    def perform(interval, verbose, rehearse)
        puts "tweeting: #{ @title }"    if verbose
        puts "would tweet: #{ @title }" if rehearse
        @tweeter.tweet(@title)
        sleep interval

        current_speaker = nil

        until @anchors.empty?
            a = @anchors.shift

            # new speaker?
            speaker = a.css('b').first
            if speaker
                current_speaker = speaker.content
                puts "found speaker: #{current_speaker}" if verbose
                next
            end

            line   = a.content
            tweet  = "#{current_speaker}: '#{line}'"
            tweets = Tweeter.break_up(tweet)

            if rehearse
                tweets.each {|msg| puts "would tweet: #{msg}"}
                sleep 1
                next
            end

            tweets.each do |msg|
                puts "tweeting: #{msg}" if @verbose
                success = false
                until success
                    begin
                        @tweeter.tweet(msg)
                        success = true
                    rescue
                        puts 'error while trying to tweet, waiting to try again' if verbose
                        sleep 180
                    end
                end
                sleep interval
            end
        end
    end
end

class Program

    attr_reader :options

    def initialize(arguments)
        @args = arguments

        @plays = []

        @options = OpenStruct.new
        @options.loop     = false
        @options.interval = 5
        @options.verbose  = false
        @options.rehearse = false
        
        unless parsed_options?
            Process.exit
        end
    end

    def curtains_up
        @plays.each do |play|
            puts 'beginning a performance...' if @options.verbose
            play.perform(@options.interval, @options.verbose, @options.rehearse)
        end
    end

    protected

    def parsed_options?
        opts = OptionParser.new
        opts.on('-l', '--loop')                    { @options.loop     = true }
        opts.on('-v', '--verbose')                 { @options.verbose  = true }
        opts.on('-r', '--rehearse')                { @options.rehearse = true }
        opts.on('-i', '--interval INTVL', Integer) {|intvl| @options.interval = intvl}

        opts.parse!(@args) rescue return false

        puts 'options parsed.' if @options.verbose

        # play html files are left in @args
        @args.each do |html|
            f      = File.open(html)
            parsed = Nokogiri::HTML(f)
            play   = Play.new(parsed)
            @plays.push(play)
        end

        puts 'All plays parsed.' if @options.verbose

        true
    end
end

program = Program.new(ARGV)
if program.options.loop
    program.curtains_up while true
else
    program.curtains_up
end
