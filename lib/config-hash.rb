Encoding.default_external = "UTF-8"

class Hash
  def -@
    NormalHash.new.merge!(self)
  end
  def +@
    ConfigHash.new(self)
  end
end

class NormalHash < Hash
end

class ConfigHash < Hash
  SEPARATORS = %r|[./]|

  def self.load(path="config.rb", var="config")
    eval <<-"end", binding, path, 0
      #{var} ||= new
      #{IO.read(path, encoding: 'utf-8') if File.exists?(path)}
      #{var}
    end
  end

  def self.setup(*list)
    new.reload!(*list)
  end

  def initialize(hash=nil)
    super()
    @root = $APP_ROOT || File.expand_path(File.dirname(caller[0]))
    merge!(hash) if hash
  end

  def reload!(*list)
    clear unless empty?
    list.each_with_index do |glob, deep|
      next unless glob
      Dir[File.join(@root, glob)].each do |path|
        path = File.expand_path(path)
        data = ConfigHash.load(path)
        keys = path.split("/")[(-1 - deep)..-2].join("/") if deep > 0
        deep == 0 ? merge!(data) : (self[keys] = data)
      end
    end
    self
  end

  def key?(key)
    super(key.to_s)
  end

  def [](key)
    key = key.to_s
    if !key?(key) && key =~ SEPARATORS
      val = self
      key.split(SEPARATORS).each do |tag|
        if !val.instance_of?(self.class)
          return super(key)
        elsif val.key?(tag)
          val = val[tag]
        elsif tag == "*" && val.size == 1
          val = val[val.keys.first]
        else
          return super(key)
        end
      end
      val
    else
      super(key)
    end
  end

  def []=(key, val)
    our = self.class
    key = key.to_s
    val = our.new(val) if val.instance_of?(Hash)
    if val.instance_of?(NormalHash)
      super(key, val)
    elsif key =~ SEPARATORS
      all = key.split(SEPARATORS)
      key = all.pop
      top = all.inject(self) do |top, tag|
        if top.key?(tag) && (try = top[tag]).instance_of?(our)
          top = try
        else
          top = top[tag] = our.new
        end
      end
      top[key] = val
    else
      super(key, val)
    end
  end

  alias store []=

  def merge!(other_hash)
    raise ArgumentError unless Hash === other_hash
    other_hash.each do |k, v|
      if block_given? && key?(k)
        self[k] = yield(k, self[k], v)
      else
        self[k] = v
      end
    end
    self
  end

  alias update merge!

  def to_hash
    Hash[self]
  end

  def method_missing(sym, *args, &block)
    if sym =~ /=$/
      self[$`] = args.first
    elsif args.empty? # or... key?(sym)
      self[sym]
    else
      super
    end
  end
end
