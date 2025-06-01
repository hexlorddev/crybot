module CryBot::Utils
  class FuzzyMatcher
    def self.find_best_match(input : String, candidates : Array(String), threshold : Float64 = 0.6) : String?
      return nil if candidates.empty?
      
      scores = candidates.map do |candidate|
        {candidate, similarity_score(input.downcase, candidate.downcase)}
      end
      
      best_match = scores.max_by { |_, score| score }
      
      if best_match[1] >= threshold
        best_match[0]
      else
        nil
      end
    end
    
    def self.similarity_score(str1 : String, str2 : String) : Float64
      return 1.0 if str1 == str2
      return 0.0 if str1.empty? || str2.empty?
      
      # Use Jaro-Winkler similarity
      jaro_score = jaro_similarity(str1, str2)
      
      # Add Winkler prefix bonus
      prefix_length = common_prefix_length(str1, str2, 4)
      jaro_score + (0.1 * prefix_length * (1 - jaro_score))
    end
    
    private def self.jaro_similarity(str1 : String, str2 : String) : Float64
      len1 = str1.size
      len2 = str2.size
      
      return 0.0 if len1 == 0 && len2 == 0
      return 0.0 if len1 == 0 || len2 == 0
      
      match_window = Math.max(len1, len2) // 2 - 1
      match_window = Math.max(0, match_window)
      
      str1_matches = Array.new(len1, false)
      str2_matches = Array.new(len2, false)
      
      matches = 0
      transpositions = 0
      
      # Find matches
      (0...len1).each do |i|
        start = Math.max(0, i - match_window)
        finish = Math.min(i + match_window + 1, len2)
        
        (start...finish).each do |j|
          next if str2_matches[j] || str1[i] != str2[j]
          
          str1_matches[i] = true
          str2_matches[j] = true
          matches += 1
          break
        end
      end
      
      return 0.0 if matches == 0
      
      # Count transpositions
      k = 0
      (0...len1).each do |i|
        next unless str1_matches[i]
        
        while !str2_matches[k]
          k += 1
        end
        
        if str1[i] != str2[k]
          transpositions += 1
        end
        k += 1
      end
      
      (matches.to_f / len1 + matches.to_f / len2 + (matches - transpositions / 2.0) / matches) / 3.0
    end
    
    private def self.common_prefix_length(str1 : String, str2 : String, max_length : Int32) : Int32
      length = Math.min(Math.min(str1.size, str2.size), max_length)
      
      (0...length).each do |i|
        return i if str1[i] != str2[i]
      end
      
      length
    end
  end
end