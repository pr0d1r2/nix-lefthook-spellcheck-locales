# frozen_string_literal: true

require "yaml"
require "open3"
require "set"

locales_dir = ENV.fetch("LEFTHOOK_SPELLCHECK_LOCALES_DIR", "config/locales")
allowed_dir = ENV.fetch("LEFTHOOK_SPELLCHECK_ALLOWED_DIR", ".")

locale_to_dict_str = ENV.fetch("LEFTHOOK_SPELLCHECK_LOCALE_DICTS", "pl:pl_PL,en:en_US")
locale_to_dict = locale_to_dict_str.split(",").to_h { |pair| pair.split(":", 2) }.freeze

def extract_values(hash, path = [])
  results = []
  hash.each do |key, value|
    current_path = path + [key]
    if value.is_a?(Hash)
      results.concat(extract_values(value, current_path))
    else
      results << { path: current_path.join("."), text: value.to_s }
    end
  end
  results
end

def clean_text(text)
  text
    .gsub(/%\{[^}]+\}/, " ")
    .gsub(/&[a-z]+;/, " ")
    .gsub(%r{<[^>]+>}, " ")
    .gsub(/[0-9]+/, " ")
    .gsub(/[^\p{L}\s-]/u, " ")
end

def extract_words(text)
  clean_text(text).split(/\s+/).select { |w| w.length > 2 }
end

def load_allowed(allowed_dir, locale_code)
  file = File.join(allowed_dir, ".hunspell_allowed_values_#{locale_code}")
  return [] unless File.exist?(file)

  File.readlines(file, chomp: true).reject { |l| l.start_with?("#") || l.strip.empty? }
end

def check_locale(file, locale_code, locale_to_dict, allowed_dir)
  dict = locale_to_dict[locale_code]
  unless dict
    $stderr.puts "No dictionary mapping for locale: #{locale_code}"
    return []
  end

  data = YAML.safe_load_file(file, permitted_classes: [], aliases: true)
  entries = extract_values(data[locale_code] || {})
  return [] if entries.empty?

  allowed = load_allowed(allowed_dir, locale_code).map(&:downcase).to_set
  errors = []

  words_by_entry = entries.filter_map do |entry|
    words = extract_words(entry[:text]).reject { |w| allowed.include?(w.downcase) }
    next if words.empty?

    [entry[:path], words]
  end

  return [] if words_by_entry.empty?

  all_words = words_by_entry.flat_map(&:last).uniq
  misspelled = hunspell_check(all_words, dict)
  return [] if misspelled.empty?

  words_by_entry.each do |path, words|
    bad = words.select { |w| misspelled.include?(w.downcase) }
    next if bad.empty?

    errors << { path: "#{locale_code}.#{path}", words: bad.uniq }
  end

  errors
end

def hunspell_check(words, dict)
  input = words.join("\n")
  stdout, status = Open3.capture2("hunspell", "-d", dict, "-l", stdin_data: input)
  unless status.success?
    $stderr.puts "hunspell failed for dict #{dict} (exit #{status.exitstatus})"
    return Set.new
  end
  stdout.lines.map { |l| l.strip.downcase }.to_set
end

locale_files = Dir[File.join(locales_dir, "*.yml")]
if locale_files.empty?
  puts "No locale files found in #{locales_dir}"
  exit 0
end

threads = locale_files.map do |file|
  locale_code = File.basename(file, ".yml")
  Thread.new { [locale_code, file, check_locale(file, locale_code, locale_to_dict, allowed_dir)] }
end

all_errors = threads.map(&:value)
has_errors = false

all_errors.each do |locale_code, file, errors|
  next if errors.empty?

  has_errors = true
  puts "\n#{file} (#{locale_code}):"
  errors.each do |err|
    puts "  #{err[:path]}: #{err[:words].join(', ')}"
  end
end

if has_errors
  puts "\nAdd false positives to .hunspell_allowed_values_<locale> (one word per line)"
  exit 1
else
  puts "All locale values pass spellcheck."
  exit 0
end
