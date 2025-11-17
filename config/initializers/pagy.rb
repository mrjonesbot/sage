# Handle both mutable and frozen Pagy::DEFAULT (frozen in Pagy 9.x and Rails 8.1.1+ / Ruby 3.4+)
# Also support both Pagy 9.x (items/overflow) and Pagy 43.x (limit/overflow)

# Pagy 43.x uses :limit instead of :items and it's already in DEFAULT
if Pagy::DEFAULT.key?(:limit)
  # Pagy 43.x - DEFAULT already has :limit, just need to set overflow if not present
  unless Pagy::DEFAULT.key?(:overflow)
    new_defaults = Pagy::DEFAULT.merge(overflow: :last_page)
    Pagy.send(:remove_const, :DEFAULT)
    Pagy.const_set(:DEFAULT, new_defaults)
  end
else
  # Pagy 9.x - use :items and :overflow
  new_defaults = Pagy::DEFAULT.merge(items: 10, overflow: :last_page)
  Pagy.send(:remove_const, :DEFAULT)
  Pagy.const_set(:DEFAULT, new_defaults)
end
