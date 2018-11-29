require 'json'
require 'date'

file = File.read "data/input.json"
data = JSON.parse(file)

# This class App will make the entire app run, including reading the JSON and calling the methods to output the result
class App
  attr_reader :data, :car_array, :rental_array

  def initialize(data)
    @data = data
    @car_array = data["cars"].map { |car| Car.new(car["id"], car["price_per_day"], car["price_per_km"]) }
    @rental_array = data["rentals"].map do |rental|
      car = car_array.find { |car| car.id === rental["car_id"]}
      Rental.new(rental["id"], car, rental["start_date"], rental["end_date"], rental["distance"])
    end
  end

  def result_to_hash
    { rentals: @rental_array.map(&:result) }
  end
end

# We create a Car class to be able to build instances of cars
class Car
  attr_reader :id, :price_per_day, :price_per_km

  def initialize(id, price_per_day, price_per_km)
    @id = id
    @price_per_day = price_per_day
    @price_per_km = price_per_km
  end
end

# We create a Rental class to be able to build instances of rentals
class Rental
  attr_reader :id, :car_id, :start_date, :end_date, :distance

  def initialize(id, car, start_date, end_date, distance)
    @id = id
    @car = car
    @start_date = Date.parse(start_date)
    @end_date = Date.parse(end_date)
    @distance = distance
  end

  # Method that computes the number of days between start and end dates
  def nb_of_days
    (@end_date - @start_date).to_i + 1
  end

  # Method that computes the discount for each day of the rental
  def discount(current_day)
    if current_day > 10
      return 0.5
    elsif current_day > 4
      return 0.7
    elsif current_day > 1
      return 0.9
    else
      return 1
    end
  end

  # Method that computes the total price for the rental, iterating through
  # each day and checking the discount rate
  def total_price
    sum = 0
    for i in 1..nb_of_days
      sum += @car.price_per_day * discount(i)
    end
    (sum + @car.price_per_km * @distance).to_i
  end

  # Method that transforms the result into the required format
  def result
    { id: @id, price: total_price }
  end
end

# We create a new instance of App that will get the input JSON
app = App.new(data)
result = app.result_to_hash

File.open("data/output.json","w") do |f|
  f.write(JSON.pretty_generate(result))
end
