#!/usr/bin/env ruby1.8
# who nathaniel k smith
# what shakesbot.rb
# why perform shakespeare plays from MIT on twitter
# when april 2010
# where http://chiptheglasses.com

require 'rubygems'
require 'nokogiri'

require 'optparse'
require 'ostruct'
require 'pp'

class Tweeter
    def initialize(secret, token)
    end

    # return an array of 140 char or less strings
    def self.break_up(string)
        broken_up = []
        while string.length > 140
            broken_up.push(string[0,139])
            string = string[0,139]
        end

        broken_up
    end

    def tweet(msg)
        puts "tweeting: #{msg}"
    end
end

class Play
    def initialize(parsed_html)
        @title   = parsed_html.css('td.play').first.content
        @tweeter = Tweeter.new(1,1)
        @anchors = parsed_html.css("a[name!='']") # ignore two irrelevant anchors
    end

    # Tweet each line, sleeping for interval seconds in between
    def perform(interval)
        @tweeter.tweet(@title)
        sleep interval

        current_speaker = nil

        until @anchors.empty?
            a = @anchors.shift

            speaker = a.css('b').first
            if speaker
                current_speaker = speaker.content
            else
                line = a.content
                tweet = "#{current_speaker}: '#{line}'"
                if tweet.length > 140
                    broken_up = Tweeter.break_up(tweet)
                    broken_up.each do |msg|
                        @tweeter.tweet(msg)
                        sleep interval
                    end
                else
                    @tweeter.tweet(tweet)
                    sleep interval
                end
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
        
        unless parsed_options?
            Process.exit
        end
    end

    def curtains_up
        @plays.each do |play|
            play.perform(@options.interval)
        end
    end

    protected

    def parsed_options?
        opts = OptionParser.new
        opts.on('-l', '--loop') { @options.loop = true }
        opts.on('-i', '--interval INTVL', Integer) {|intvl| @options.interval = intvl}

        opts.parse!(@args) rescue return false

        # play html files are left in @args
        @args.each do |html|
            f      = File.open(html)
            parsed = Nokogiri::HTML(f)
            play   = Play.new(parsed)
            @plays.push(play)
        end

        true
    end
end

program = Program.new(ARGV)
if program.options.loop
    program.curtains_up while true
else
    program.curtains_up
end
