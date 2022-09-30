# structure:
# lines = {
#   line_1: [  { name: '', go: { in: 2, change: 2, out: 6 }, back: { in: 6, change: 2, out: 2 } },  ] 
# }
#
#

code_pos = 0
line_pos = 1
name_pos = 2
foward_in_pos = 3
foward_change_pos = 4
foward_out_pos = 5
back_in_pos = 4
back_change_pos = 5
back_out_pos = 6

@lines = {}
@combinations = {}

def get_station_line(station_name, current_line = nil)
  lines_of_station = []
  @lines.each_with_index do |line, index|
    next if line[0] == current_line

    unless line[1].find { |station| station[:name] == station_name }.nil?
      if current_line.nil?
        lines_of_station << { line: line[0], pos: line[1].find_index { |station| station[:name] == station_name } }
      else
        lines_of_station << { line: line[0], line_pos: index, comb_pos: line[1].find_index { |station| station[:name] == station_name } }
      end
    end
  end
  lines_of_station
end

File.open('stations.csv').each do |file_line|
  station = file_line.split(',')
  next if station[0] == 'id'

  line = "line_#{station[line_pos]}"
  @lines[line] = [] if @lines[line].nil?
  @lines[line] << { code: station[code_pos],
                    name: station[name_pos],
                    foward: { in: station[foward_in_pos], change: station[foward_change_pos], out: station[foward_out_pos] },
                    back: { in: station[back_in_pos], change: station[back_change_pos], out: station[back_out_pos] } }
end

@lines.each do |line, stations|
  stations.each do |station|
    get_station_line(station[:name], line).each do |combination|
      @combinations[line] = {} if @combinations[line].nil?
      @combinations[line][combination[:line]] = [] if @combinations[line][combination[:line]].nil?
      @combinations[line][combination[:line]] << { name: station[:name],
                                                   line_pos: combination[:line_pos],
                                                   comb_pos: combination[:comb_pos] }
    end
  end
end

def same_line?(lines_station1, lines_station2)
  lines1 = lines_station1.map { |line| line[:line] }
  lines2 = lines_station2.map { |line| line[:line] }
  lines1.each do |line|
    return line if lines2.include? line
  end
  nil
end

def move_same_lines(line, lines_station1, lines_station2)
  pos1 = lines_station1.select { |station_line| station_line[:line] == line }[0][:pos]
  pos2 = lines_station2.select { |station_line| station_line[:line] == line }[0][:pos]
  stations = pos1 < pos2 ? @lines[line][pos1..pos2] : @lines[line][pos2..pos1].reverse

  stations.each do |station|
    p "#{station[:name]}, #{line.gsub('_', ' ')}"
  end
end

def get_trayectory(station1, station2)
  lines_station1 = get_station_line(station1)
  lines_station2 = get_station_line(station2)
  same_line = same_line?(lines_station1, lines_station2)
  if !same_line.nil?
    move_same_lines(same_line, lines_station1, lines_station2)
  else

  end
end


# p @lines
get_trayectory('Plaza de Armas', 'Baquedano')
