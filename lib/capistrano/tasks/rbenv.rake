namespace :rbenv do
  task :validate do
    on roles(:all) do
      rbenv_ruby = fetch(:rbenv_ruby)
      if rbenv_ruby.nil?
        error "rbenv: rbenv_ruby is not set"
        exit 1
      end

      if test "[ ! -d #{fetch(:rbenv_ruby_dir)} ]"
        error "rbenv: #{rbenv_ruby} is not installed or not found in #{fetch(:rbenv_ruby_dir)}"
        exit 1
      end
    end
  end

  task :map_bins do
    rbenv_prefix = fetch(:default_env).map { |k, v| "#{k.to_s.upcase}=#{v.shellescape}" }.join " "
    rbenv_prefix += " RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

    SSHKit.config.command_map[:rbenv] = "#{fetch(:rbenv_path)}/bin/rbenv"

    fetch(:rbenv_map_bins).each do |command|
      SSHKit.config.command_map.prefix[command.to_sym].unshift(rbenv_prefix)
    end
  end
end

Capistrano::DSL.stages.each do |stage|
  after stage, 'rbenv:validate'
  after stage, 'rbenv:map_bins'
end

namespace :load do
  task :defaults do
    set :rbenv_path, -> {
      rbenv_path = fetch(:rbenv_custom_path)
      rbenv_path ||= if fetch(:rbenv_type, :user) == :system
        "/usr/local/rbenv"
      else
        "~/.rbenv"
      end
    }

    set :rbenv_ruby_dir, -> { "#{fetch(:rbenv_path)}/versions/#{fetch(:rbenv_ruby)}" }
    set :rbenv_map_bins, %w{rake gem bundle ruby}
  end
end
