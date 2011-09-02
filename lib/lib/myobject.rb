#-*- coding:utf-8  -*-

# 俺俺インスタンスをつくるためにクラスを用意した
# 典型的なrequireを書きこんでいく
# 読み込み済みモジュール
#   kconv time
class MyObject
  def initialize
    require "kconv"
    require "time"
    require "optparse"
  end
end
