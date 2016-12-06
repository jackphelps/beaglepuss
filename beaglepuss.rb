module Beaglepuss
  class << self
    attr_accessor :config
  end

  class Config
    attr_accessor :shuffle_salt, :min_mask_length, :base_alphabet, :prefix_separator
    attr_reader :encoded_chunk_size, :unencoded_chunk_size

    def initialize
      # Integer # so your app doesn't produce the same masked IDs as everyone else's
      @shuffle_salt           = 0
      # Integer, default 8 # ensure even small numeric IDs produce a relatively opaquely sized mask
      @min_mask_length        = 8
      # prefix identified by the first occurrence of this character; do not use it in your prefixes!
      @prefix_separator       = "_"

      # alternative hashing alphabet
      # include Radix (https://github.com/rubyworks/radix) and pass an array to base
      # radix creates a new base number system from the array contents for easy conversion
      @base_alphabet          = 36

      # I think I can calc efficient values for these based on alphabet but was having trouble...
      @encoded_chunk_size     = 2
      @unencoded_chunk_size   = 3
    end
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
    def decode(masked_id)
      find(Beaglepuss.decode(masked_id))
    end

    def beaglepuss?
      true
    end
  end

  module InstanceMethods
    def masked_id
      Beaglepuss.encode(id, beaglepuss_prefix)
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
    raw = strip_prefix(masked_id)
    unswapped = unswap(raw)
    unshuffle(unswapped).to_i
  end

  private

  def pad_and_shuffle(numeric_id)
    id_str = numeric_id.to_s
    padded = id_str.rjust(pad_id_to_size(id_str), "0")
    shuffle(padded)
  end

  def shuffle(str)
    array = str.split("")
    array = array.size.times.map{|index| (array[index].to_i + index) % 10}
    rotations = rotations(array)
    array.size.times.map{ array.rotate!(rotations).pop }.join
  end

  def unshuffle(str)
    array = str.split("")
    rotations = rotations(array)
    new_array = []
    array.size.times do
      new_array << array.pop
      new_array.rotate!(rotations * -1)
    end
    new_array.size.times.map{|index| (new_array[index].to_i - index) % 10}.join
  end

  def rotations(array)
    char_sum = array.reduce(0){|sum, char| sum + char.to_i }
    # use the sum of the integer characters -- which remains consistent regardless of the order -- plus the salt
    # modulo size minus 1 and add one after so we never rotate(0)
    (config.shuffle_salt + char_sum % (array.size - 1)) + 1
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
