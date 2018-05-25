# config-hash

`config-hash` is a Ruby gem that provides a safe, homoiconic, Ruby hash supporting dot notation.

## Examples

```ruby
# basic config
config.age = 33

# you can use the dotenv gem to populate ENV values
config.database = {
  database: "movies",
  adapter:  "mysql2",
  host:     ENV["DB_HOST"],
  username: ENV["DB_USER"],
}

# some nesting of values
config.school = {
  teachers: {
    veterans: %w[ William Peggy Thomas ],
    upstarts: ["Connor", "Amber", "Bob" ],
    unsure: {
      hired: ["Trey"],
      processing: ["Mike", "Larry", "Tina"],
    }
  }
}

# ==[ Add comments, functions, and data right in the config file ]==

# proc to create grouping hash
grouper = proc do |str|
  str.split("\n").inject({}) do |obj, row|
    row = row.split("#", 2)[0].split(/[,|]/).map(&:strip)
    row.each {|col| obj[col] = row[0]} if row.size > 1
    obj
  end
end

# supply some data to group
config.foods = grouper[<<-end]
  meat|chicken,beef,salmon # ,pork
  dairy|milk,cheese,ice cream
  # junk|candy,monster,burrito
  dessert|cake,pie,brownies
end

# the above yields:
# config.foods = {
#   "meat"      => "meat",
#   "chicken"   => "meat",
#   "beef"      => "meat",
#   "salmon"    => "meat",
#   "dairy"     => "dairy",
#   "milk"      => "dairy",
#   "cheese"    => "dairy",
#   "ice cream" => "dairy",
#   "dessert"   => "dessert",
#   "cake"      => "dessert",
#   "pie"       => "dessert",
#   "brownies"  => "dessert",
# }

# this allows the following:
config.foods.cake # => "dessert"
config.foods.mean # => "meal"
config["foods.milk"] # => "dairy"
config["foods.jerky"] # => nil
```

## License

This software is licensed under terms of the MIT License.
