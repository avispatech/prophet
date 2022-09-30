require 'csv'

all_stations = []

first_and_ended_station = { linea1: (101..127), linea2: (201..226), linea3: (301..321), linea4: (401..423), linea5: (501..30), linea6: (601..610) }
combination = combination(all_stations)

CSV.foreach('stations.csv', headers: true, col_sep: ',') do |row|
  all_stations << { name: row['Nombre'], id: row['id'].to_i, line: row['Línea'] }
end

115 - 504
def route(initial_id, final_id)
  initial_line = initial_id.to_s.chars.first.to_i
  final_line = final_id.to_s.chars.first.to_i
  route = []

  if initial_line == final_line
    Array (first_and_ended_station["linea#{1}".to_sym]).each.with_index(1) do |num, index|
      id = if initial_id < final_id ? final_line + index : final_line - index
      route << all_stations.find { |stn| stn[:id] == id}
    end
  end
  

end

def combination(all_stations)
 combinations = all_stations.group_by { |stn| stn[:name] }
 combinations.each do |key, value|
  combinations.delete(key) if value.count < 2
 end

 arr = combinations.map do |key, value|
  value.map do |v|
    v[:id]
  end
 end
end
