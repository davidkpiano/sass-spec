require 'minitest'
require 'pathname'
require_relative 'test'
require_relative 'test_case'


class SassSpec::Runner

  def initialize(options = {})
    @options = options
  end

  def run
    unless @options[:silent] || @options[:tap]
      puts "Recursively searching under directory '#{@options[:spec_directory]}' for test files to test '#{@options[:engine_adapter]}' with."
      puts @options[:engine_adapter].version
    end

    test_cases = _get_cases
    SassSpec::Test.create_tests(test_cases, @options)

    minioptions = []
    if @options[:verbose]
      minioptions.push '--verbose'
    end

    if @options[:tap]
      require 'minitap'
      Minitest.reporter = Minitap::TapY
    end

    exit Minitest.run(minioptions)
  end


  def _get_cases
    cases = []
    glob = File.join(@options[:spec_directory], "**", "#{@options[:input_file]}")
    Dir.glob(glob) do |filename|
      input = Pathname.new(filename)
      @options[:output_styles].each do |output_style|
        folder = File.dirname(filename)
        output_file_name = @options["#{output_style}_output_file".to_sym]
        expected_file_path = File.join(folder, output_file_name + ".css")
        clean_file_name = File.join(folder, output_file_name + ".clean")
        if File.file?(expected_file_path) && !File.file?(expected_file_path.sub(/\.css$/, ".skip")) && filename.include?(@options[:filter])
          clean = File.file?(clean_file_name)
          cases.push SassSpec::TestCase.new(input.realpath(), expected_file_path, output_style, clean, @options)
        end
      end
    end
    cases
  end

end
