# 指定秒数ごとにrun関数をループする
# 各メソッドを必要に応じて再定義して使う。
#
#   使い方:
#   someinstance.extend RunPerSecModule
#   someinstance.run(ループのインターバルsec){
#     __block__for__yield__
#   }
#   
# OR
#   
#   class ThisDo < MyObject
#     include RunPerSecModule
#   .....
# 
module RunPerSecModule
  # ループフラグ
  @loop_flg

  # main_loopをループする
  #   sec : ループ間隔 秒
  # before_run_loop,ループ,after_run_loopの順番で実行する。
  # ループの中身はloop_hook_pre,与えられたブロック,main_loop,loop_hook_postの順番で実行する
  def run(sec)
	init_run_per_sec_module
	before_run_loop
	while @loop_flg
	  loop_hook_pre
	  yield
	  main_loop
	  loop_hook_post
	  sleep sec
	end
	after_run_loop
  end

  # 外からは使わない
  # 無限ループフラグを立てる
  def init_run_per_sec_module
	@loop_flg = true
  end

  # runのループを止める
  def stop_run
    @loop_flg = false
  end
  
  # runメソッドが呼ばれるとループの前に一回だけ実行される
  def before_run_loop
  end

  # runメソッドのloopの中で最初に実行される
  def loop_hook_pre
  end

  # runメソッドのloopの中で実行される
  def main_loop
  end

  # runのループの中でmain_loopのあとで実行される
  def loop_hook_post
  end
  
  # runメソッドが呼ばれるとループのあとで実行される
  def after_run_loop
  end
end
