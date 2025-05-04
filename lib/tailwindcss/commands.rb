require "tailwindcss/ruby"

module Tailwindcss
  module Commands
    class << self
      def compile_command(debug: false, namespace: nil, **kwargs)
        debug = ENV["TAILWINDCSS_DEBUG"].present? if ENV.key?("TAILWINDCSS_DEBUG")
        rails_root = defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)

        input_filename, output_filename = get_input_and_output_filename(namespace)

        command = [
          Tailwindcss::Ruby.executable(**kwargs),
          "-i", rails_root.join("app/assets/tailwind/#{input_filename}.css").to_s,
          "-o", rails_root.join("app/assets/builds/#{output_filename}.css").to_s,
        ]

        command << "--minify" unless (debug || rails_css_compressor?)

        postcss_path = rails_root.join("postcss.config.js")
        command += ["--postcss", postcss_path.to_s] if File.exist?(postcss_path)

        command
      end

      def watch_command(always: false, poll: false, **kwargs)
        compile_command(**kwargs).tap do |command|
          command << "-w"
          command << "always" if always
          command << "-p" if poll
        end
      end

      def command_env(verbose:)
        {}.tap do |env|
          env["DEBUG"] = "1" if verbose
        end
      end

      private

      def rails_css_compressor?
        defined?(Rails) && Rails&.application&.config&.assets&.css_compressor.present?
      end

      def get_input_and_output_filename(namespace)
        if namespace != nil
          unless File.exist?("app/assets/tailwind/#{namespace}.css")
            raise "No file named #{namespace}.css exists in app/assets/tailwind"
          end

          if namespace == "application"
            raise "application.css is the default input file for tailwind and cannot be used as namespace. If you want the normal behaviour of tailwindcss (to compile application.css into tailwind.css), just omit the namespace parameter."
          end
        end

        input_filename = namespace || "application"
        output_filename = namespace || "tailwind"
        return input_filename, output_filename
      end
    end
  end
end
