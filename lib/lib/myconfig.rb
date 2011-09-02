#-*- coding:utf-8 -*-
#~/config.ymlに配置された設定ファイルを読んで返す
class MyConfig
  @@file = nil
  @@data = nil

  def self.set(filename)
    @@file = filename
  end

  def self.hoge
    return @@file
  end

  # 設定オブジェクトを返す
  def self.get
    self.read if @@data.nil?
    return @@data
  end

  private

  def self.read
    require 'yaml'
    @@file = "#{ENV['HOME']}/config.yml"  if @@file.nil?
    @@data = YAML.load_file("#{@@file}")
  rescue
    raise "Can't Read config.yml"
  end

  def self.reload
    self.read
  end

  def self.dispose
    @@file = nil
    @@data = nil
  end
end


