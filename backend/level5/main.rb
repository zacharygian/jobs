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
  attr_reader :id, :car_id, :start_date, :end_date, :distance, :actions, :options

  def initialize(id, car, start_date, end_date, distance)
    @id = id
    @car = car
    @start_date = Date.parse(start_date)
    @end_date = Date.parse(end_date)
    @distance = distance
    @actions = []
    @options = []
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

  # Method that computes the commission for each party
  def commission(id)
    fee = (total_price * 0.3).to_i
    if id == 'insurance'
      fee / 2
    elsif id == 'assistance'
      nb_of_days * 100
    elsif id == 'drivy'
      fee / 2 - nb_of_days * 100
    end
  end

  # Method that creates all the necessary actions, computing the associated values and pushing them into an array of actions
  def create_actions
    @actions << Action.new('driver', 'debit', total_price + compute_extras[0] + compute_extras[1]).action_result
    @actions << Action.new('owner', 'credit', (total_price * 0.7 + compute_extras[0]).to_i).action_result
    @actions << Action.new('insurance', 'credit', commission('insurance')).action_result
    @actions << Action.new('assistance', 'credit', commission('assistance')).action_result
    @actions << Action.new('drivy', 'credit', commission('drivy') + compute_extras[1]).action_result
  end

  # Method defining the options array according to the id of the rental
  def options
    if @id == 1
      @options = %w(gps baby_seat)
    elsif @id == 2
      @options = %w(additional_insurance)
    elsif id == 3
      @options
    end
  end

  # Method computing the owner extra and the drivy extra by iterating through
  # the options array and multiplying the cost by the number of days, returns an array with both computed sums
  def compute_extras
    owner_extra = 0
    drivy_extra = 0

    @options.each do |option|
      if option == "gps"
        owner_extra += 500 * nb_of_days
      elsif option == "baby_seat"
        owner_extra += 200 * nb_of_days
      elsif option == "additional_insurance"
        drivy_extra += 1000 * nb_of_days
      end
    end
    [owner_extra, drivy_extra]
  end

  # Method that transforms the result into the required format
  def result
    { id: @id, options: options, actions: create_actions }
  end
end

# We create an Action class to be able to build instances of actions
class Action
  attr_reader :actor, :type, :amount

  def initialize(actor, type, amount)
    @actor = actor
    @type = type
    @amount = amount
  end

  # Method that correctly formats the action result into a hash
  def action_result
    { who: @actor, type: @type, amount: @amount }
  end
end

app = App.new(data)
result = app.result_to_hash

File.open("data/output.json","w") do |f|
  f.write(JSON.pretty_generate(result))
end
