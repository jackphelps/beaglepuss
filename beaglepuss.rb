module Beaglepuss
  require "beaglepuss/config"
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Config.new
    yield(config)
  end

  def beaglepuss(beaglepuss_prefix)
    cattr_accessor :beaglepuss_prefix
    self.beaglepuss_prefix = beaglepuss_prefix
    extend ClassMethods
    include InstanceMethods
  end

  module ClassMethods
    def find(id)
      id = Beaglepuss.decode(id)
      super
    end

    # These basically work, but they're really a terrible idea.

    # def find_by(*args)
    #   super unless args[0] && args[0].is_a?(Hash) && args[0][:id] && Beaglepuss.decodable?(args[0][:id])
    #   args[0][:id] = Beaglepuss.decode(args[0][:id])
    #   super
    # end

    # def where(*args)
    #   super unless args[0] && args[0].is_a?(Hash) && args[0][:id] && Beaglepuss.decodable?(args[0][:id])
    #   args[0][:id] = Beaglepuss.decode(args[0][:id])
    #   super
    # end

    def beaglepuss?
      true
    end
  end

  module InstanceMethods
    def to_param
      Beaglepuss.encode(numeric_id, beaglepuss_prefix)
    end

    def id
      to_param
    end

    def numeric_id
      self.read_attribute(:id)
    end

    def beaglepuss?
      true
    end
  end

  def encode(numeric_id, prefix = nil)
    shuffled = pad_and_shuffle(numeric_id)
    swapped  = swap(shuffled)
    prefix.present? ? "#{prefix}#{config.prefix_separator}#{swapped}" : swapped
  end

  def decode(masked_id)
    # if fallbacks are OFF and we're passed an integer id, raise a record not found error
    raise ActiveRecord::RecordNotFound if config.prevent_fallback == true && integer_id?(masked_id)
    # if passed anything other than a string, do whatever ActiveRecord would do
    return masked_id unless masked_id.is_a?(String)
    raw = strip_prefix(masked_id)
    unswapped = unswap(raw)
    unshuffle(unswapped).to_i
  end

  def decodable?(var)
    var.is_a?(Integer) || var.is_a?(String) ? true : false
  end

  private

  def integer_id?(id)
    return true if id.is_a?(Integer)
    # check if a string is a string version of an integer
    return false unless id.is_a?(String)
    id.to_i.to_s == id ? true : false
  end

  def pad_and_shuffle(numeric_id)
    id_str = numeric_id.to_s
    padded = id_str.rjust(pad_id_to_size(id_str), "0")
    shuffle(padded)
  end

  def shuffle(str)
    array, rotations = shuffle_setup(str)
    # array = (0...array.size).map{|index| (array[index].to_i + index) % 10}
    array.size.times.map{ array.rotate!(rotations).pop }.join("")
  end

  def unshuffle(str)
    array, rotations = shuffle_setup(str)
    new_array = []
    array.size.times do
      new_array << array.pop
      new_array.rotate!(rotations * -1)
    end
    new_array.join
    # (0...new_array.size).map{|index| (new_array[index].to_i - index) % 10}.join
  end

  def shuffle_setup(str)
    array = str.split("")
    char_sum = array.reduce(0){|sum, char| sum + char.to_i }
    # use the sum of the integer characters -- which remains consistent regardless of the order -- plus the salt
    # modulo size minus 1 and add one after so we never rotate(0)
    rotations = ((char_sum) % (array.size - 1)) + 1
    [array, rotations]
  end

  def strip_prefix(str)
    str.gsub(prefix_regex, "")
  end

  def swap(str)
    ar = str.split("")
    loops = ar.size / config.unencoded_chunk_size
    loops.times.map{
      ar.pop(config.unencoded_chunk_size).join.to_i.to_s(config.base_alphabet).rjust(config.encoded_chunk_size, "0")
    }.reverse.join
  end

  def unswap(str)
    ar = str.split("")
    loops = ar.size / config.encoded_chunk_size
    loops.times.map{
      ar.pop(config.encoded_chunk_size).join.to_i(config.base_alphabet).to_s.rjust(config.unencoded_chunk_size, "0")
    }.reverse.join
  end

  def pad_id_to_size(str)
    min = [str.size, config.min_mask_length / config.encoded_chunk_size * config.unencoded_chunk_size].max
    loop do
      # count up until both chunk sizes are factors
      return min if min % config.unencoded_chunk_size == 0
      min += 1
    end
  end

  def prefix_regex
    str = "^(.*?)#{config.prefix_separator}"
    Regexp.new(str)
  end
end
ActiveRecord::Base.extend Beaglepuss
