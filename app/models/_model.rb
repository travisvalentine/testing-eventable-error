class Model
  class << self; include EM::Eventable; end;

  @@datas = {}
  @@fields = {}

  def initialize(attributes = {})
    # coverts string to symbol
    attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    attributes.each { |key, value|
      self.send("#{key}=", value) if self.class.fields.include? key
    }
  end

  def save
    unless self.class.exists?(self.id)
      self.class.datas << self
      self.class.persist()
      self.class.trigger(:created)
      true
    else
      self.class.persist()
      self.class.trigger(:updated)
    end
  end

  def update_attribute(k, v)

  end

  # obj-c stuff
  def initWithCoder(decoder)
    self.init
    self.class.fields.each { |prop|
      value = decoder.decodeObjectForKey(prop.to_s)
      self.send((prop.to_s + "=").to_s, value) if value
    }
    self
  end

  # called when saving an object to NSUserDefaults
  def encodeWithCoder(encoder)
    self.class.fields.each { |prop|
      encoder.encodeObject(self.send(prop), forKey: prop.to_s)
    }
  end

  def destroy
    @@datas[self.class.name] = @@datas[self.class.name].reject { |m| self.id == m.id }
    self.class.persist()
    self.class.trigger(:removed)
  end

  # class methods

  def self.default_sort(items)
    items
  end

  def self.create(attributes={})
    self.new(attributes).tap { |k| k.save() }
  end

  def self.key(k)
    @@tid = k.to_s
  end

  def self.datas
    @@datas
  end

  def self.find(k=nil, v=nil, &block)
    if k
      datas.select { |m| m.send(k) == v }
    else
      datas.select(&block)
    end
  end

  def self.count
    datas.length
  end

  def self.exists?(id)
    !find(:id, id).empty?
  end

  def self.attrs(*items)
    items.each { |f| attr_accessor(f) }

    @@datas[self.name] = []
    @@fields[self.name] = items

    events()
    load()
  end

  def self.events
    on(:created) { trigger(:changed) }
    on(:removed) { trigger(:changed) }
    on(:seeded) { trigger(:changed) }
  end

  def self.all
    default_sort(datas)
  end

  def self.to_s
    "#{name} #{fields}"
  end

  def self.clear
    @@datas[self.name] = []
    persist()
    trigger(:removed)
  end

  def self.datas
    @@datas[self.name]
  end

  def self.seed(data)
    @@datas[self.name] = data
    persist()
    trigger(:seeded)
  end

  def self.fields
    @@fields[self.name]
  end

  def self.persist
    NSUserDefaults.standardUserDefaults[self.name] = datas.map { |d| NSKeyedArchiver.archivedDataWithRootObject(d) }
  end

  def self.load
    @@datas[self.name] = datasource.map { |d| NSKeyedUnarchiver.unarchiveObjectWithData(d) }
  end

  def self.datasource
    NSUserDefaults.standardUserDefaults[self.name] ||= []
    NSUserDefaults.standardUserDefaults[self.name]
  end
end