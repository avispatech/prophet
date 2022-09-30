require 'csv'
stations = {}
stations_names = {}
combination_stations = []

CSV.foreach('stations.csv', headers: true) do |row|
  stations[row[0]] = {line: row[1],
                      name: row[2],
                      forward_enter: row[3],
                      forward_change: row[4],
                      forward_exit: row[5],
                      backward_enter: row[6],
                      backward_change: row[7],
                      backward_exit: row[8],
                      distance_begin: row[9],
                      distance_end: row[10],
                      }
  stations_names[row[0]] = row[2]
end

stations_names.values.tally.each do |station, count|
  next if count == 1
  combination_stations << station
end

combination_network = {}

stations.select {|k,v| combination_stations.include?(v[:name])}.map do |k,v|
  combination_network[v[:name]] = [] if combination_network[v[:name]].nil?
  combination_network[v[:name]] << k
end

def calculate_routes(initial_station, end_station, stations, combination_network)
  initial_station = initial_station.to_i
  end_station = end_station.to_i
  route = []
  current_line = initial_station[0].to_s
  destination_line = end_station[0].to_s
  direction = initial_station > end_station ? 'forward' : 'backward'
  ordered_stations = direction == 'forward' ? stations.keys.sort : stations.keys.sort.reverse
  ordered_stations.each do |station_id|
    station_id = station_id.to_i
    station_name = stations[station_id.to_s][:name]
    next if station_id > initial_station
    next if station_id < end_station
    
    
    # puts "Station can change to destination line: #{combination_network[station_name].select { |v| v != station_id.to_s }[0][0] == destination_line}" if !combination_network[station_name].nil?
    # puts "Should change line? : #{current_line != destination_line && !combination_network[station_name].nil? && (combination_network[station_name].select { |v| v != station_id.to_s }[0][0] == destination_line)}"
    current_line = station_id[0]
    if current_line != destination_line && !combination_network[station_name].nil? && (combination_network[station_name].select { |v| v != station_id.to_s }[0][0] == destination_line)
      puts "Station Combination #{combination_network[station_name]} #{station_name}"
      puts "Can Change Lines"
      route << "#{station_id} -#{station_name} - #{stations[station_id.to_s][:line]}" if combination_network[station_name].include?(station_id)
      current_line = combination_network[station_name].select { |v| v != station_id }
    else
      route << "#{station_id} -#{station_name} - #{stations[station_id.to_s][:line]}"
    end
    
  end
  route.each{|r| puts r}
end

calculate_routes(220,103, stations, combination_network)