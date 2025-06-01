require "process"
require "file"
require "../utils/fuzzy_matcher"

module CryBot::Commands
  struct CommandResult
    getter response : String
    getter success : Bool
    getter data : Hash(String, String)?
    
    def initialize(@response : String, @success : Bool, @data : Hash(String, String)? = nil)
    end
  end
  
  class Processor
    getter config : Hash(String, String)
    getter plugins : Array(Plugin)
    
    def initialize(@config : Hash(String, String))
      @plugins = [] of Plugin
      @command_history = [] of String
    end
    
    def load_plugins
      plugin_dir = "plugins"
      return unless Dir.exists?(plugin_dir)
      
      Dir.glob("#{plugin_dir}/*.cryplugin").each do |plugin_file|
        begin
          load_plugin(plugin_file)
        rescue ex
          puts "⚠️  Failed to load plugin #{plugin_file}: #{ex.message}".colorize(:yellow)
        end
      end
      
      puts "🔌 Loaded #{@plugins.size} plugins".colorize(:green) if @plugins.size > 0
    end
    
    def execute(command_text : String) : CommandResult
      @command_history << command_text
      
      # Normalize command
      normalized = command_text.downcase.strip
      
      # Check for exit commands
      if ["exit", "goodbye", "quit", "stop"].any? { |exit_cmd| normalized.includes?(exit_cmd) }
        puts "👋 Goodbye!".colorize(:cyan)
        exit(0)
      end
      
      # Try built-in commands first
      result = try_builtin_commands(normalized)
      return result if result.success
      
      # Try plugins
      @plugins.each do |plugin|
        result = plugin.try_execute(normalized)
        return result if result.success
      end
      
      # If no command matched, try fuzzy matching for suggestions
      suggestion = suggest_command(normalized)
      if suggestion
        CommandResult.new("I didn't understand that command. Did you mean: #{suggestion}?", false)
      else
        CommandResult.new("I didn't understand that command. Try saying 'help' for available commands.", false)
      end
    end
    
    private def try_builtin_commands(command : String) : CommandResult
      case command
      when .includes?("help")
        get_help_response
      when .includes?("open browser")
        open_browser
      when .includes?("show cpu"), .includes?("cpu usage")
        show_cpu_usage
      when .includes?("show memory"), .includes?("memory usage")
        show_memory_usage
      when .includes?("git status")
        git_status
      when .includes?("git commit")
        git_commit
      when .includes?("list files"), .includes?("show files")
        list_files
      when .includes?("current directory"), .includes?("where am i")
        current_directory
      when .includes?("date"), .includes?("time")
        current_time
      when .includes?("weather")
        get_weather
      when .includes?("run script")
        run_script(command)
      else
        CommandResult.new("", false)
      end
    end
    
    private def get_help_response : CommandResult
      help_text = <<-HELP
      Available commands:
      • Open browser - Launch your default web browser
      • Show CPU usage - Display current CPU utilization
      • Show memory usage - Display RAM usage
      • Git status - Show git repository status
      • Git commit - Commit changes to git
      • List files - Show files in current directory
      • Current directory - Show current location
      • Date/Time - Show current date and time
      • Run script [name] - Execute a script file
      • Weather - Get weather information
      • Help - Show this help message
      • Exit/Goodbye - Shutdown CryBot
      HELP
      
      CommandResult.new(help_text, true)
    end
    
    private def open_browser : CommandResult
      begin
        if system_has_command?("xdg-open")
          Process.run("xdg-open", ["https://google.com"], output: Process::Redirect::Close, error: Process::Redirect::Close)
          CommandResult.new("Opening browser", true)
        elsif system_has_command?("open") # macOS
          Process.run("open", ["https://google.com"], output: Process::Redirect::Close, error: Process::Redirect::Close)
          CommandResult.new("Opening browser", true)
        else
          CommandResult.new("Cannot open browser. No suitable command found.", false)
        end
      rescue
        CommandResult.new("Failed to open browser", false)
      end
    end
    
    private def show_cpu_usage : CommandResult
      begin
        if system_has_command?("top")
          # Get CPU usage from top command
          result = `top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d',' -f1`
          cpu_usage = result.strip
          CommandResult.new("CPU usage is #{cpu_usage} percent", true)
        else
          CommandResult.new("Cannot get CPU usage. Top command not available.", false)
        end
      rescue
        CommandResult.new("Failed to get CPU usage", false)
      end
    end
    
    private def show_memory_usage : CommandResult
      begin
        if system_has_command?("free")
          result = `free -h | grep Mem | awk '{print "Used: " $3 " of " $2}'`
          CommandResult.new("Memory usage: #{result.strip}", true)
        else
          CommandResult.new("Cannot get memory usage. Free command not available.", false)
        end
      rescue
        CommandResult.new("Failed to get memory usage", false)
      end
    end
    
    private def git_status : CommandResult
      begin
        if system_has_command?("git")
          result = `git status --porcelain 2>/dev/null`
          if result.empty?
            CommandResult.new("Git repository is clean", true)
          else
            changes = result.lines.size
            CommandResult.new("Git has #{changes} changes", true)
          end
        else
          CommandResult.new("Git is not installed", false)
        end
      rescue
        CommandResult.new("Not in a git repository or git error", false)
      end
    end
    
    private def git_commit : CommandResult
      begin
        # This is a simplified version - in practice you'd want to be more careful
        result = `git add -A && git commit -m "CryBot automated commit" 2>&1`
        if $?.success?
          CommandResult.new("Git commit successful", true)
        else
          CommandResult.new("Git commit failed: #{result.strip}", false)
        end
      rescue
        CommandResult.new("Git commit failed", false)
      end
    end
    
    private def list_files : CommandResult
      begin
        files = Dir.glob("*").select { |f| File.file?(f) }.first(5)
        if files.empty?
          CommandResult.new("No files in current directory", true)
        else
          file_list = files.join(", ")
          more = Dir.glob("*").select { |f| File.file?(f) }.size > 5 ? " and more" : ""
          CommandResult.new("Files: #{file_list}#{more}", true)
        end
      rescue
        CommandResult.new("Failed to list files", false)
      end
    end
    
    private def current_directory : CommandResult
      begin
        dir = Dir.current
        CommandResult.new("Current directory is #{File.basename(dir)}", true)
      rescue
        CommandResult.new("Failed to get current directory", false)
      end
    end
    
    private def current_time : CommandResult
      now = Time.local
      CommandResult.new("The time is #{now.to_s("%I:%M %p")} on #{now.to_s("%A, %B %d")}", true)
    end
    
    private def get_weather : CommandResult
      # This would typically call a weather API
      # For now, return a mock response
      CommandResult.new("I cannot get weather information yet. Weather API integration coming soon!", false)
    end
    
    private def run_script(command : String) : CommandResult
      # Extract script name from command
      parts = command.split
      script_index = parts.index("script")
      
      if script_index && script_index + 1 < parts.size
        script_name = parts[script_index + 1]
        
        # Try different extensions
        ["", ".py", ".rb", ".sh", ".cr"].each do |ext|
          full_name = "#{script_name}#{ext}"
          if File.exists?(full_name)
            return execute_script_file(full_name)
          end
        end
        
        CommandResult.new("Script #{script_name} not found", false)
      else
        CommandResult.new("Please specify a script name", false)
      end
    end
    
    private def execute_script_file(filename : String) : CommandResult
      begin
        case File.extname(filename)
        when ".py"
          result = `python3 #{filename} 2>&1`
        when ".rb"
          result = `ruby #{filename} 2>&1`
        when ".sh"
          result = `bash #{filename} 2>&1`
        when ".cr"
          result = `crystal run #{filename} 2>&1`
        else
          return CommandResult.new("Unknown script type", false)
        end
        
        if $?.success?
          CommandResult.new("Script executed successfully", true)
        else
          CommandResult.new("Script failed: #{result.strip}", false)
        end
      rescue
        CommandResult.new("Failed to execute script", false)
      end
    end
    
    private def suggest_command(input : String) : String?
      # This would use fuzzy matching to suggest similar commands
      # For now, just a simple implementation
      commands = [
        "open browser", "show cpu usage", "show memory", "git status", 
        "git commit", "list files", "current directory", "help"
      ]
      
      # Simple similarity check
      best_match = commands.min_by { |cmd| levenshtein_distance(input, cmd) }
      
      if levenshtein_distance(input, best_match) <= 3
        best_match
      else
        nil
      end
    end
    
    private def levenshtein_distance(s1 : String, s2 : String) : Int32
      # Simple Levenshtein distance implementation
      return s2.size if s1.empty?
      return s1.size if s2.empty?
      
      matrix = Array.new(s1.size + 1) { Array.new(s2.size + 1, 0) }
      
      (0..s1.size).each { |i| matrix[i][0] = i }
      (0..s2.size).each { |j| matrix[0][j] = j }
      
      (1..s1.size).each do |i|
        (1..s2.size).each do |j|
          cost = s1[i-1] == s2[j-1] ? 0 : 1
          matrix[i][j] = [
            matrix[i-1][j] + 1,     # deletion
            matrix[i][j-1] + 1,     # insertion
            matrix[i-1][j-1] + cost # substitution
          ].min
        end
      end
      
      matrix[s1.size][s2.size]
    end
    
    private def load_plugin(plugin_file : String)
      # Plugin loading would be implemented here
      # For now, just a placeholder
    end
    
    private def system_has_command?(command : String) : Bool
      !`which #{command} 2>/dev/null`.empty?
    end
  end
  
  # Plugin interface
  abstract class Plugin
    abstract def try_execute(command : String) : CommandResult
    abstract def name : String
    abstract def description : String
  end
end