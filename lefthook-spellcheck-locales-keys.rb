# frozen_string_literal: true

require "yaml"
require "open3"

locales_dir = ENV.fetch("LEFTHOOK_SPELLCHECK_LOCALES_DIR", "config/locales")
allowed_file = ENV.fetch("LEFTHOOK_SPELLCHECK_ALLOWED_KEYS_FILE", ".hunspell_allowed_keys")
dict = ENV.fetch("LEFTHOOK_SPELLCHECK_KEYS_DICT", "en_US")

def extract_keys(hash, path = [])
  results = []
  hash.each do |key, value|
    current_path = path + [key]
    results << key.to_s
    results.concat(extract_keys(value, current_path)) if value.is_a?(Hash)
  end
  results
end

def key_words(key)
  key.tr("_-", " ").split(/\s+/).select { |w| w.length > 2 }
end

def load_allowed(file)
  return [] unless File.exist?(file)

  File.readlines(file, chomp: true).reject { |l| l.start_with?("#") || l.strip.empty? }
end

def hunspell_check(words, dict)
  return Set.new if words.empty?

  input = words.join("\n")
  stdout, status = Open3.capture2("hunspell", "-d", dict, "-l", stdin_data: input)
  unless status.success?
    $stderr.puts "hunspell failed (exit #{status.exitstatus})"
    return Set.new
  end
  stdout.lines.map { |l| l.strip.downcase }.to_set
end

locale_files = Dir[File.join(locales_dir, "*.yml")]
if locale_files.empty?
  puts "No locale files found in #{locales_dir}"
  exit 0
end

allowed = load_allowed(allowed_file).map(&:downcase).to_set

all_keys = locale_files.flat_map do |file|
  data = YAML.load_file(file)
  data.each_value.flat_map { |v| v.is_a?(Hash) ? extract_keys(v) : [] }
end.uniq

all_words = all_keys.flat_map { |k| key_words(k) }.uniq
all_words.reject! { |w| allowed.include?(w.downcase) }

misspelled = hunspell_check(all_words, dict)

if misspelled.empty?
  puts "All locale keys pass English spellcheck."
  exit 0
end

puts "Misspelled words in locale keys:"
bad_keys = all_keys.select do |k|
  key_words(k).any? { |w| misspelled.include?(w.downcase) }
end

bad_keys.each do |k|
  bad_words = key_words(k).select { |w| misspelled.include?(w.downcase) }
  puts "  #{k}: #{bad_words.join(', ')}"
end

puts "\nAdd false positives to #{allowed_file} (one word per line)"
exit 1
