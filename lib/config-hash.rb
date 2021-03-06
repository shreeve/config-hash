class Hash
  def -@; NormalHash[self]; end
  def +@; ConfigHash[self]; end
end

class NormalHash < Hash
end

class ConfigHash < Hash
  SEPARATORS ||= %r|[./]|

  # allow "obj.zip" (for a zip code, etc.)
  undef_method :zip

  def self.[](hash=nil)
    new(hash)
  end

  def self.load(path="config.rb", list=nil, name: "config")
    path = File.expand_path(path)
    data = eval <<~"end", binding, path, 0
      #{name} ||= new
      #{IO.read(path, encoding: 'utf-8') if File.readable?(path)}
      #{name}
    end
    data.load(*list) if list && !list.empty?
    data
  end

  def initialize(hash=nil)
    super()
    update(hash) if hash
  end

  def load(*list)
    [list].each do |root, glob|
      root = File.expand_path(root)
      pref = root.size + 1
      full = File.join([root, glob].compact)
      list = Dir[full].sort {|a,b| [a.count('/'), a] <=> [b.count('/'), b]}
      list.each do |path|
        info = File.dirname(path[pref...] || '')
        data = ConfigHash.load(path)
        info == '.' ? update(data) : (self[info] = data)
      end
    end
    self
  end

  def key?(key)
    super(key.to_s)
  end

  def [](key)
    our = self.class
    key = key.to_s

    if !key?(key) && key =~ SEPARATORS && (ary = key.split SEPARATORS)
      val = ary.inject(self) do |obj, sub|
        if not our === obj  then return super(key)
        elsif obj.key?(sub) then obj[sub]
        elsif sub == "*"    then obj[obj.keys.first]
        else                     return super(key)
        end
      end
    else
      super(key)
    end
  end

  def []=(key, val)
    our = self.class
    key = key.to_s
    val = our.new(val) if val.instance_of?(Hash)

    if !key?(key) && key =~ SEPARATORS && (ary = key.split SEPARATORS)
      key = ary.pop
      obj = ary.inject(self) do |obj, sub|
        obj.key?(sub) && our === (try = obj[sub]) ? try : (obj[sub] = our.new)
      end
      obj[key] = val
    else
      super(key, val)
    end
  end

  def update(hash, nuke=false)
    raise ArgumentError unless Hash === hash
    clear if nuke
    hash.each {|key, val| self[key] = val}
    self
  end

  def update!(hash)
    update(hash, true)
  end

  def to_hash
    Hash[self]
  end

  def method_missing(name, *args, &code)
    case
      when name =~ /=$/ then self[$`] = args.first
      when args.empty?  then self[name]
      else super
    end
  end
end
