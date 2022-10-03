require 'csv'
require 'hashie'

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
  'siguiente' => :next_station_distance
}.freeze

# Me genera el último hash creado con nil:nil, nil:nil
all_stations = []
CSV.foreach('stations.csv', headers: true) do |row|
  headers = row.headers.map { |header| HEADER_TRANSLATIONS[header] }
  all_stations << Hashie::Mash.new(headers.zip(row.map { |_, v| v }).to_h)
end

station_hash_by_id = Hashie::Mash.new
station_names_by_id = Hashie::Mash.new
combinations = Hashie::Mash.new

all_stations.each do |stn|
  station_hash_by_id[stn.id] = stn
  station_names_by_id[stn.id] = stn.name
end

group_by_station_name = all_stations.group_by { |e| e[:name] }
select_combination_station = group_by_station_name.select! { |_, v| v.count > 1 }
arr = select_combination_station.map { |k, value| [[k, value.map { |v| v[:id] }].flatten, value.map { |v| v[:line] }] }
arr.each { |element| element[0].each { |e| combinations[e] = element[1] } }

# 'lo valledor' -> 'parque almagro'
def search_before_and_after_combination_stations(initial)

end