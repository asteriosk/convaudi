ConvAudi
========

Requirements
-----
The following gems are required for it to run:
popen4, thread_storm, progressbar

Usage
-----

    $ ruby convaudi.rb [options]

    Available options:
        -c, --concurrency [NUM_OF_CPUS]  The number of threads executing conversion at any given point. Default: number of processors
        -q, --quality [QUALITY]          The quality in which to transform the converted files. Default: 320k
        -p, --pretend                    Show only what the script is going to do: do not really convert or touch any file. Default: false
        -d, --delete                     Whether to delete the original file upon successful (only) converion. Default: false
        -i, --input [EXTENSIONS]         The filetypes that will be converted. Default: .mpc,.flac,.wma
        -o, --output-format [EXTENSION]  The output filetype. Default: .m4a
            --help                       Show this help message

