require 'hashie'
require 'terminal-table'
require 'benchmark'
require 'parallel'
require 'thor'
require_relative './station_loader.rb'
require_relative './planner.rb'





# station_hash.each do |k, station|
#   puts "#{k} #{station.name} -> #{station.connecting_station_id}"
# end


stations = StationLoader.new(file: "stations.csv").load.station_hash
planner = Planner.set(stations: stations)








# loop do
#   puts 'Elige actividad a realizar (ruta/matriz)'
#   option = ARGF.readline.strip
#   next calculate_route(station_names:)   if option == 'ruta'
#   next calculate_matrices if option == 'matriz'
  

#   puts 'Continuar (si/no)'
#   break if ARGF.readline.strip == 'no'
# end
# ARGF.readline

# ARGF.readline 
# res.each do |matrix|
#   matrix.each do |route, result|
#     puts "#{route}: #{result.stations.reverse.map(&:id).join(',')}"
#   end
#   ARGF.readline    
# end

class Metro < Thor
  package_name 'metro'
  desc 'benchmark', 'benchmarks all matrix calculations'
  def benchmark
    res = []
    Benchmark.bm do |benchmark|
      benchmark.report('processes') { res << calculate_matrix_parallel_processes }
      benchmark.report('threads') { res << calculate_matrix_parallel_threads }
      benchmark.report('inline') { res << calculate_matrix }
    end
    res
  end

  
  desc 'matrix METHOD', 'calculates a distance matrix the specified method'
  method_options chance: :string
  method_options output: :string
  def matrix(method='processes')
    puts options.inspect
    chance = options[:chance].to_f
    mtx = case method
    when 'processes'
      calculate_matrix_parallel_processes(chance)
    when 'threads'

      calculate_matrix_parallel_threads(chance)
    when 'inline'
      calculate_matrix(chance)
    end
    mtx.each do |route, result|
      puts "#{route}: #{result.cost}\t #{result.stations.map(&:id).join(',')}"
    end

    if options[:output]
      File.open(options[:output], 'w') do |file|
        mtx.each do |route, result|
          file.puts  "#{route}: #{result.cost}\t #{result.stations.map(&:id).join(',')}"
        end
      end
    end
  end

  desc 'stations', 'list all known stations'
  def stations
    station_names = StationLoader.new(file: "./stations.csv").load.station_names
    station_names.each do |code, name|
      puts "#{code}\t#{name}"
    end
  end

  desc 'calculate ORIGIN DESTINATION', 'calculates best route between stations'
  def calculate_route(origin, destination)
    station_names = StationLoader.new(file: "./stations.csv").load.station_names
    puts 'Estación de Origen: '
    origin = origin.strip
    puts station_names[origin]
    raise if station_names[origin].nil? 
  
    puts 'Estación de Destino: '
    destination = destination.strip
    puts station_names[destination]
    raise if station_names[destination].nil?
  
    res = Planner.get.travel(from: origin.to_s, to: destination.to_s)
    puts res.stations.reverse.map { |s| "#{s.id} #{s.name} (#{s.line})"}.join("\n")
  
  rescue StandardError => e
    puts e.inspect
  end

  private 

  def prepare(filter: 0.04)
    puts "Preparing. filter: #{filter}"
    random = Random.new(100)
    cropped_stations = StationLoader.new(file: "./stations.csv")
                                    .load.station_names
                                    .keys
                                    .select { |k|  random.rand > (1 - filter) }
    crop_station_zip = []
    cropped_stations.each { |o| cropped_stations.each { |d| crop_station_zip << [o, d] } }
    puts "#{crop_station_zip.length} stations tuples loaded for test"
    crop_station_zip
  end

  def calculate_matrix_parallel_threads(chance)
    tuples = prepare(filter: chance)
    Parallel.map(tuples, in_threads: 12) do |from, to|
      ["#{from}->#{to}", Planner.get.travel(from:, to:)]
    end.to_h
  end
  
  def calculate_matrix_parallel_processes(chance)
    tuples = prepare(filter: chance)
    Parallel.map(tuples, in_processes: 12) do |from, to|
      # puts "#{from} -> #{to}"
      ["#{from}->#{to}", Planner.get.travel(from:, to:)]
    end.to_h
  end
  
  def calculate_matrix(chance)
    distance_matrix = {}
    prepare(filter: chance).each do |from, to|
      result = Planner.get.travel(from:, to:)
      # puts "#{from} -> #{to} = #{result.cost}"
      distance_matrix["#{from}->#{to}"] = result
    end
    distance_matrix
  end

end