require "file"
require "json"
require "../crypto/encryptor"

module CryBot::Utils
  class Logger
    getter log_file : String
    getter encryption_enabled : Bool
    getter encryptor : Crypto::Encryptor?
    
    def initialize(@log_file : String = "crybot.crylog", @encryption_enabled : Bool = true)
      @encryptor = @encryption_enabled ? Crypto::Encryptor.new : nil
      initialize_log_file
    end
    
    def log_interaction(content : String, type : String)
      entry = {
        "timestamp" => Time.local.to_s,
        "type" => type,
        "content" => content,
        "session_id" => session_id
      }
      
      write_log_entry(entry)
    end
    
    def log_error(exception : Exception)
      entry = {
        "timestamp" => Time.local.to_s,
        "type" => "error",
        "content" => exception.message || "Unknown error",
        "backtrace" => exception.backtrace?.try(&.join("\n")) || "",
        "session_id" => session_id
      }
      
      write_log_entry(entry)
    end
    
    def log_system_event(event : String, details : String = "")
      entry = {
        "timestamp" => Time.local.to_s,
        "type" => "system",
        "content" => event,
        "details" => details,
        "session_id" => session_id
      }
      
      write_log_entry(entry)
    end
    
    def read_logs(limit : Int32 = 100) : Array(Hash(String, String))
      logs = [] of Hash(String, String)
      
      return logs unless File.exists?(@log_file)
      
      begin
        File.each_line(@log_file) do |line|
          next if line.strip.empty?
          
          if @encryption_enabled && @encryptor
            begin
              decrypted_entry = @encryptor.not_nil!.decrypt_log_entry(line.strip)
              logs << decrypted_entry.transform_values(&.to_s)
            rescue
              # Skip corrupted entries
              next
            end
          else
            begin
              entry = Hash(String, String).from_json(line)
              logs << entry
            rescue
              # Skip malformed entries
              next
            end
          end
          
          break if logs.size >= limit
        end
      rescue ex
        puts "Error reading logs: #{ex.message}".colorize(:red)
      end
      
      logs.reverse # Most recent first
    end
    
    def get_session_stats : Hash(String, Int32)
      logs = read_logs(1000)
      
      stats = {
        "total_interactions" => 0,
        "commands" => 0,
        "responses" => 0,
        "errors" => 0,
        "system_events" => 0
      }
      
      current_session = session_id
      
      logs.each do |entry|
        next unless entry["session_id"]? == current_session
        
        stats["total_interactions"] += 1
        
        case entry["type"]?
        when "input"
          stats["commands"] += 1
        when "output"
          stats["responses"] += 1
        when "error"
          stats["errors"] += 1
        when "system"
          stats["system_events"] += 1
        end
      end
      
      stats
    end
    
    def export_logs(output_file : String, decrypt : Bool = false)
      logs = read_logs(10000) # Get all logs
      
      if decrypt || !@encryption_enabled
        # Export as readable JSON
        File.write(output_file, logs.to_pretty_json)
        puts "📄 Logs exported to #{output_file} (#{logs.size} entries)".colorize(:green)
      else
        # Export encrypted logs as-is
        if File.exists?(@log_file)
          File.copy(@log_file, output_file)
          puts "📄 Encrypted logs copied to #{output_file}".colorize(:green)
        end
      end
    end
    
    def clean_old_logs(days_to_keep : Int32 = 30)
      cutoff_time = Time.local - days_to_keep.days
      logs = read_logs(10000)
      
      recent_logs = logs.select do |entry|
        if timestamp = entry["timestamp"]?
          begin
            Time.parse(timestamp, "%Y-%m-%d %H:%M:%S %z") > cutoff_time
          rescue
            true # Keep entries with unparseable timestamps
          end
        else
          true
        end
      end
      
      # Rewrite log file with only recent entries
      temp_file = "#{@log_file}.tmp"
      
      begin
        File.open(temp_file, "w") do |file|
          recent_logs.reverse.each do |entry| # Restore original order
            if @encryption_enabled && @encryptor
              encrypted_line = @encryptor.not_nil!.encrypt_log_entry(entry)
              file.puts encrypted_line
            else
              file.puts entry.to_json
            end
          end
        end
        
        File.rename(temp_file, @log_file)
        removed_count = logs.size - recent_logs.size
        puts "🧹 Cleaned #{removed_count} old log entries".colorize(:yellow) if removed_count > 0
      rescue ex
        File.delete(temp_file) if File.exists?(temp_file)
        puts "⚠️  Failed to clean old logs: #{ex.message}".colorize(:red)
      end
    end
    
    def close
      # Final session stats
      stats = get_session_stats
      log_system_event("session_end", "Commands: #{stats["commands"]}, Errors: #{stats["errors"]}")
    end
    
    private def initialize_log_file
      unless File.exists?(@log_file)
        File.touch(@log_file)
        puts "📝 Created new log file: #{@log_file}".colorize(:blue)
      end
      
      # Log session start
      log_system_event("session_start", "CryBot v#{CryBot::VERSION}")
      
      if @encryption_enabled
        puts "🔐 Log encryption enabled".colorize(:green)
      else
        puts "⚠️  Log encryption disabled".colorize(:yellow)
      end
    end
    
    private def write_log_entry(entry : Hash(String, String))
      begin
        File.open(@log_file, "a") do |file|
          if @encryption_enabled && @encryptor
            encrypted_line = @encryptor.not_nil!.encrypt_log_entry(entry)
            file.puts encrypted_line
          else
            file.puts entry.to_json
          end
        end
      rescue ex
        puts "⚠️  Failed to write log entry: #{ex.message}".colorize(:red)
      end
    end
    
    private def session_id : String
      @session_id ||= Time.local.to_unix.to_s(16)
    end
  end
end