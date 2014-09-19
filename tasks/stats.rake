WHERE_WIDTH, LINES_WIDTH = 12, 4

desc "Lines of code"
task :stats do

  stats = []
  stats << loc('client', 'lib', 'mock.rb')
  stats << loc('server', 'rails')
  stats << loc('mock',   'lib/daylight/mock.rb')
  stats << loc('docs',   'app')

  puts row("WHERE", "LOC")
  puts line

  stats.each do |where, loc|
    puts row(where, loc)
  end

  puts line
  puts row("TOTAL", stats.map(&:last).reduce(:+))
end

def loc(name, dir, filter=nil)
  cmd = "egrep -v \"^\s*(#.*)?$\" -r #{dir}"
  cmd << "| grep -v #{filter}" if filter
  cmd << "| wc -l"

  [name, Integer(`#{cmd}`)]
end

def row(where, lines)
  ['|', where.ljust(WHERE_WIDTH), '|', lines.to_s.rjust(LINES_WIDTH), '|'].join(" ")
end

def line
  ['|', '-'*WHERE_WIDTH, '|', "#{'-'*(LINES_WIDTH-1)}:", '|'].join(" ")
end
