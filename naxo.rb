# frozen_string_literal: true

def route(initial_station, final_station, metro)
  return metro[initial_station][:name] if initial_station == final_station

  visited_stations = []
  combinatined_station = []
  current_station = initial_station
  while current_station != final_station
    puts "Current station #{current_station}"
    next_station = metro[current_station][:next]
    puts "Next station #{next_station}"
    current_station = metro.map { |k, v| k if v[:previous].to_i == next_station.to_i }.compact.first
  end
  puts "Arrived #{current_station}"
end

metro = {}
File.open('stations.csv') do |file|
  file.each_line do |line|
    information = line.split(',')
    next if information[0] == 'id'

    metro[information[0]] = { line: information[1], name: information[2],
                              previous: information[9], next: information[10] }
  end
end

initial_station = '101'
final_station = '123'

puts route(initial_station, final_station, metro)
