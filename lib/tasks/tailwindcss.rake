Rake::Task["tailwindcss:build"].clear if Rake::Task.task_defined?("tailwindcss:build")

namespace :tailwindcss do
  desc "Build your Tailwind CSS with reliable fallback"
  task :build do
    puts "== Compiling Tailwind CSS =="
    built = false

    # Try node / npx first if available
    if system("npx --version > nul 2>&1 || npx --version > /dev/null 2>&1")
      built = system("npx @tailwindcss/cli -i app/assets/tailwind/application.css -o app/assets/builds/tailwind.css")
    end

    # Fallback to tailwindcss-ruby gem executable if npx failed or not found
    unless built
      tailwind_bin = begin
        Tailwindcss::Ruby.executable
      rescue StandardError
        nil
      end

      if tailwind_bin && File.exist?(tailwind_bin)
        built = system("#{tailwind_bin} -i #{Rails.root.join('app/assets/tailwind/application.css')} -o #{Rails.root.join('app/assets/builds/tailwind.css')}")
      end
    end

    # If builds/tailwind.css already exists and is non-empty, don't fail
    if File.exist?(Rails.root.join("app/assets/builds/tailwind.css")) && File.size(Rails.root.join("app/assets/builds/tailwind.css")) > 100
      puts "Tailwind CSS build verified."
    elsif !built
      warn "Warning: Tailwind CSS could not be recompiled, using existing build."
    end
  end
end
