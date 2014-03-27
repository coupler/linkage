module Linkage
  module Helpers
    module CSV
      def csv_filename(options)
        File.expand_path(options[:filename], options[:dir] || '.')
      end

      def open_csv_for_reading(options)
        filename = csv_filename(options)
        if !File.exist?(filename)
          raise MissingError, "#{filename} does not exist"
        end
        ::CSV.open(filename, 'rb', :headers => true)
      end

      def open_csv_for_writing(options)
        filename = csv_filename(options)
        if !options[:overwrite] && File.exist?(filename)
          raise ExistsError, "#{filename} exists and not in overwrite mode"
        end
        if options[:dir]
          FileUtils.mkdir_p(File.dirname(filename))
        end
        ::CSV.open(filename, 'wb')
      end
    end
  end
end
