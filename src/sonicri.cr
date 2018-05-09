require "./sonicri/*"

Sonicri::Terminal.setup
user = Sonicri::User.new
user.run
