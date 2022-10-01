require 'hashie'

class Planner

  def initialize(stations:)
    @stations = stations
  end

  def self.set(stations:)
    @planner = Planner.new(stations:)
  end

  def self.get = @planner

  def travel(from:, to:, direction: 0, visited_lines: [], station_hash: @stations, depth: 0)
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