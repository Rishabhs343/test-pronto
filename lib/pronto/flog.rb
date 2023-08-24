require 'pronto'
require 'flog'
require 'parallel'

module Pronto
  class Flog < Runner
    def run
      messages = []

      report_by_file = analyze_complexity_for_all_files
      report_by_file.each do |file, report|
        next if report.empty?

        messages << new_message(file, report)
      end

      display_messages(messages)
      messages
    end

    def analyze_complexity_for_all_files
      report_by_file = {}

      Parallel.each(files, in_threads: Parallel.processor_count) do |file|
        report = `flog #{file}`
        report_by_file[file] = report
      end

      report_by_file
    end

    def files
      @files ||= ruby_patches.map(&:new_file_full_path)
    end

    def new_message(file, report)
      Message.new(file, nil, :warning, report, nil, self.class)
    end

    def display_messages(messages)
      messages.each do |message|
        puts "File: #{message.path}"
        puts message.msg
        puts "\n"
      end
    end
  end
end
