module SuperCallbacks
  module Helpers
    # (modified) File activesupport/lib/active_support/core_ext/hash/deep_merge.rb, line 18
    def self.deep_merge_hashes_and_combine_arrays(this_hash, other_hash, &block)
      self.deep_merge_hashes_and_combine_arrays!(this_hash.dup, other_hash, &block)
    end

    # (modified) File activesupport/lib/active_support/core_ext/hash/deep_merge.rb, line 23
    def self.deep_merge_hashes_and_combine_arrays!(this_hash, other_hash, &block)
      this_hash.merge!(other_hash) do |key, this_val, other_val|
        if this_val.is_a?(Hash) && other_val.is_a?(Hash)
          self.deep_merge_hashes(this_val, other_val, &block)
        elsif this_val.is_a?(Array) && other_val.is_a?(Array)
          this_val + other_val
        elsif block_given?
          block.call(key, this_val, other_val)
        else
          other_val
        end
      end
    end

    def self.deep_array_and_hash_dup(enumerables, levels_left = nil)
      return enumerables if levels_left && levels_left == 0

      if enumerables.is_a?(Array)
        enumerables = enumerables.dup
        enumerables.each_with_index do |enumerable, index|
          enumerables[index] = deep_array_and_hash_dup(enumerable, levels_left.nil? ? nil : levels_left - 1)
        end
        enumerables
      elsif enumerables.is_a?(Hash)
        enumerables = enumerables.dup
        enumerables.each do |key, value|
          enumerables[key] = deep_array_and_hash_dup(value, levels_left.nil? ? nil : levels_left - 1)
        end
        enumerables
      else
        enumerables
      end
    end
  end
end
