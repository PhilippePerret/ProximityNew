# encoding: UTF-8
require 'benchmark'
REG_PREPARED = /^(STRINGASSEZLONG|AUTRECHOSE)/.freeze
AUTRE_CHOSE = "AUTRECHOSE".freeze
Benchmark.bm do |x|
    x.report { 100000.times {
      a = "un mot".start_with?("STRINGASSEZLONG") || "un mot".start_with?("AUTRECHOSE")
    }}
    STRING_PREPARED = "STRINGASSEZLONG".freeze
    x.report { 100000.times {
      a = "un mot".start_with?(STRING_PREPARED) || "un mot".start_with?(AUTRE_CHOSE)
    }}
    REG_STRING_PREPARED = "STRINGASSEZLONG".freeze
    x.report { 100000.times {
      a = "un mot".start_with?(REG_PREPARED)
    }}
    x.report { 100000.times {
      a = "un mot".match?(/^(STRINGASSEZLONG|AUTRECHOSE)/)
    }}
    x.report { 100000.times {
      a = "un mot".match?(REG_PREPARED)
    }}
end
