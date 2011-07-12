require 'rubygems'
require 'thread_storm'
require 'fileutils'
require 'optparse'
require 'popen4'
require 'progressbar'

class Converter
  
  # Default contructor - sets the default values for all variables
  def initialize()
    @ext_to_convert = ['.flac', '.wma', '.mpc']
    
    @concurrency = 2    
    @pretend     = false
    @remove      = false
    
    @output_format = ".m4a"
    @quality       = "320k"
    
    @failed = Array.new
    
    parse_options()
    @threads = ThreadStorm.new({:size => @concurrency})    
  end
  
  # Parses command line arguments and configures the script
  def parse_options()
    options = OptionParser.new do |opts|
      opts.banner = "Usage: convert.rb [options]"

      opts.separator ""
      opts.separator "Available options:"

      opts.on("-c", "--concurrency [NUM_OF_CPUS]", "The number of threads executing conversion at any given point. Default: number of processors") do |arg|
        @concurrency = Integer(arg)
      end
      
      opts.on("-q", "--quality [QUALITY]", "The quality in which to transform the converted files. Default: 320k") do |arg|
        @quality = arg
      end
      
      opts.on("-p", "--pretend", "Show only what the script is going to do: do not really convert or touch any file. Default: false") do
        @pretend = true
      end
      
      opts.on("-d", "--delete", "Whether to delete the original file upon successful (only) converion. Default: false") do
        @remove = true
      end
     
      opts.on("-i", "--input [EXTENSIONS]", "The filetypes that will be converted. Default: .mpc,.flac,.wma") do |arg|
        @ext_to_convert = arg.split(",")
      end 
      
      opts.on("-o", "--output-format [EXTENSION]", "The output filetype. Default: .m4a") do |arg|
        @output_format = arg
      end
      
      opts.on_tail("--help", "Show this help message") do
        puts opts
        exit
      end      
    end
    
    options.parse!
  end
  
  def convert()
    mutex = Mutex.new
    length = 0
    files = Hash.new
    
    @ext_to_convert.each do |ext|
      Dir['**/*'+ext].each do |original|
        converted = original.chomp(File.extname(original)) + @output_format;
        files[original] = converted
      end
    end
    
    bar = ProgressBar.new("Conversion", files.length)
    
    #We fill the threadpool with all the files. Every thread takes over the converion of one file at a time
    files.each do |original, converted|
      @threads.execute {
    
        command = "ffmpeg -y -i \"#{original}\" -aq 255 -ab #{@quality} -map_meta_data 0:0,s0 -ac 2 -ar 44100 \"#{converted}\""

        if !@pretend
            exit_code,error_output = execute(command)
          if exit_code==0
            FileUtils.mv(original, original+'.converted');
          else
            mutex.synchronize { @failed << command + "\n" + error_output + " Exit code: " + exit_code.to_s }
          end
        end  
        
        #Update the bar by one
        mutex.synchronize { bar.inc }
      }
    end

    @threads.join()
    @threads.shutdown()
    
    bar.finish
    
    if @failed.length!=0
      puts "Some commands failed to execute: " + @failed.to_s
    end
  end
  
  
  # Executes a given system command
  def execute(command, verbose=false)
    #puts command
    error_output = ""

    status = Open4.popen4(command) {|pid, stdin, stdout, stderr|
      out = Thread.new do
        stdout.each_line do |line|
          if verbose
            puts line
          end
        end
      end

      err = Thread.new do
        stderr.each_line do |line|
          error_output += line
        end
      end

      out.join
      err.join
    }
    
    return Integer(status), error_output
  end

end

conv = Converter.new
conv.convert
