require 'hashie'

class StationLoader

  HEADER_TRANSLATIONS = {
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

  def initialize(file:)
    @file = file
  end

  def load
    file_stations = read
    process file_stations
  end

  attr_reader :station_names
  attr_reader :station_hash

  def process(stations)
    @station_hash = Hashie::Mash.new
    @station_names = Hashie::Mash.new
    combinations = Hashie::Mash.new
    stations.each do |station|
      @station_hash[station.id] = station
      @station_names[station.id] = station.name
    end

    station_network = @station_names.values.tally

    connecting_station_names = station_network.select { |x, y| y.to_i > 1 }
                                              .map { |name, _| name}


    connecting_station_names.each do |station_name|
      sid1, sid2 = @station_names.select { |k, v| v == station_name }.map { |k, v| k }
      
      @station_hash[sid1].connecting_station_id = sid2
      @station_hash[sid1].connecting_station = station_hash[sid2]
      @station_hash[sid1].connecting = true

      @station_hash[sid2].connecting_station_id = sid1
      @station_hash[sid2].connecting_station = station_hash[sid1]
      @station_hash[sid2].connecting = true
    end
    self
  end

  def read
    file_stations = nil
    File.open(@file) do |file|
      lines = file.map { |line| line.split(',') }
      headers = lines.first.map { |col| HEADER_TRANSLATIONS[col] }
      body = lines[1..-1]
    
      file_stations = body.map do |line|
        Hashie::Mash.new(headers.zip(line).to_h)
      end
    end
    file_stations
  end
end
