require 'hashie'
require 'terminal-table'
require 'benchmark'
require 'parallel'

stations = nil

header_translations = {
  'id' => :id,
  'Línea' => :line,
  'Nombre' => :name,
  'IdaEntrada' => :forward_entrance,
  'IdaCambio' => :forward_exchange,
  'IdaSalida' => :forward_exit,
  'VueltaEntrada' => :backward_entrance,
  'VueltaCambio' => :backward_exchange,
  'VueltaSalida' => :backward_exit,
  'anterior' => :previous_station_distance,
  'siguiente' => :next_station_distance,
}

File.open("stations.csv") do |file|
  lines = file.map { |line| line.split(',') }
  headers = lines.first
  headers = headers.map { |col| header_translations[col] }
  body = lines[1..-1]

  stations = body.map do |line|
    Hashie::Mash.new(headers.zip(line).to_h)
  end
end

station_hash = Hashie::Mash.new
station_names = Hashie::Mash.new
combinations = Hashie::Mash.new
stations.each do |station|
  station_hash[station.id] = station
  station_names[station.id] = station.name
end

station_network = station_names.values.tally

connecting_station_names = station_network.select { |x, y| y.to_i > 1 }
                                          .map { |name, _| name}


connecting_station_names.each do |station_name|
  sid1, sid2 = station_names.select { |k, v| v == station_name }.map { |k, v| k }
  
  station_hash[sid1].connecting_station_id = sid2
  station_hash[sid1].connecting_station = station_hash[sid2]
  station_hash[sid1].connecting = true

  station_hash[sid2].connecting_station_id = sid1
  station_hash[sid2].connecting_station = station_hash[sid1]
  station_hash[sid2].connecting = true
end

# station_hash.each do |k, station|
#   puts "#{k} #{station.name} -> #{station.connecting_station_id}"
# end


STATIONS = station_hash

class Planner

  def initialize(db: {})
    @db = db
  end

  def travel(from:, to:, direction: 0, visited_lines: [], station_hash: STATIONS, depth: 0)
    cache_key = "#{from}->#{to}"
    station = station_hash[from]
    destination_station = station_hash[to]

    visited_lines << station.line unless visited_lines.include? station.line
    visited_lines = visited_lines.dup
    return Hashie::Mash.new({ stations: [station], cost: 1}) if from == to

    results = []
    unless destination_station.line == station.line
      if station.connecting
        comb_station = station.connecting_station
        if comb_station.id == to
          return Hashie::Mash.new({ stations: [station], cost: 1 })
        end
        unless visited_lines.include? comb_station.line
          visited_lines << station.line

          results << travel(from: comb_station.id, to:, direction: 1, visited_lines: visited_lines.dup, depth: depth + 1)
          results << travel(from: comb_station.id, to:, direction: -1, visited_lines: visited_lines.dup, depth: depth + 1)
        end
      end
    end

    next_station = station_hash[(from.to_i + 1).to_s]
    prev_station = station_hash[(from.to_i - 1).to_s]
    if direction != 1 and prev_station
      results << travel(from: prev_station.id.to_s, to:, direction: -1, visited_lines: visited_lines.dup, depth: depth + 1)
    end
    if direction != -1 and next_station
      results << travel(from: next_station.id.to_s, to:, direction: 1, visited_lines: visited_lines.dup, depth: depth + 1)
    end
    
    # This is a dead end
    return Hashie::Mash.new({ stations: [station], cost: 10_000 }) if results.empty?

    sorted_results = results.select { |x| x.cost < 10_000 }.sort_by(&:cost)
    return Hashie::Mash.new({ stations: [station], cost: 10_000 }) if sorted_results.empty?

    best_result = sorted_results.first
    best_result.stations << station
    best_result.cost += 1

    # @result_db[cache_key] = best_result
    # puts "Will return(FINAL) #{best_result}"
    best_result
  rescue StandardError => e
    puts "Error: #{e.inspect}"
  end
end
random = Random.new(100)
CROPPED_STATIONS = STATIONS.keys.select { |k|  random.rand > 0.96 }
CROP_STATION_ZIP = []
CROPPED_STATIONS.each { |o| CROPPED_STATIONS.each { |d| CROP_STATION_ZIP << [o, d] } }
puts "#{CROP_STATION_ZIP.length} stations tuples loaded for test"

def calculate_matrix_parallel_threads
  tuples = CROP_STATION_ZIP

  Parallel.map(tuples, in_threads: 10) do |from, to|
    # puts "#{from} -> #{to}"
    ["#{from}->#{to}", Planner.new.travel(from:, to:)]
  end.to_h
end

def calculate_matrix_parallel_processes
  tuples = CROP_STATION_ZIP

  Parallel.map(tuples, in_processes: 4) do |from, to|
    # puts "#{from} -> #{to}"
    ["#{from}->#{to}", Planner.new.travel(from:, to:)]
  end.to_h
end

def calculate_matrix
  distance_matrix = {}
  CROP_STATION_ZIP.each do |from, to|
    planner = Planner.new(db: distance_matrix)
    result = planner.travel(from:, to:)
    # puts "#{from} -> #{to} = #{result.cost}"
    distance_matrix["#{from}->#{to}"] = result
  end

  # distance_matrix.each do |route, result|
  #   puts "#{route}\t#{result.cost}"
  # end
  distance_matrix
end

def calculate_matrices
  res = []
  Benchmark.bm do |benchmark|
    benchmark.report('processes') { res << calculate_matrix_parallel_processes }
    # benchmark.report('threads') { res << calculate_matrix_parallel_threads }
    benchmark.report('inline') { res << calculate_matrix }
  end
  ARGF.readline 
  res.each do |matrix|
    matrix.each do |route, result|
      puts "#{route}: #{result.stations.reverse.map(&:id).join(',')}"
    end
    ARGF.readline    
  end
end

def calculate_route(station_names:)
  puts 'Estación de Origen: '
  origin = ARGF.readline.strip
  puts origin.inspect
  puts station_names[origin]
  raise if station_names[origin].nil? 

  puts 'Estación de Destino: '
  destination = ARGF.readline.strip
  puts station_names[destination]
  raise if station_names[destination].nil?


  res = Planner.new.travel(from: origin.to_s, to: destination.to_s)
  puts res.stations.reverse.map { |s| "#{s.id} #{s.name} (#{s.line})"}.join("\n")

rescue StandardError => e
  puts e.inspect
  retry
end

loop do
  puts 'Elige actividad a realizar (ruta/matriz)'
  option = ARGF.readline.strip
  next calculate_route(station_names:)   if option == 'ruta'
  next calculate_matrices if option == 'matriz'
  

  puts 'Continuar (si/no)'
  break if ARGF.readline.strip == 'no'
end
# ARGF.readline
# calculate_matrices
