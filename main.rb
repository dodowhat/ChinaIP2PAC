require 'http'
require 'yaml'

def calculate_subnet_mask(subnet_prefix_size)
  binary_str_1 = "1" * subnet_prefix_size
  binary_str_0 = "0" * (32 - subnet_prefix_size)
  binary_str = binary_str_1 + binary_str_0

  mask_str = ""
  slice_length = 8
  4.times do |i|
    mask_str += binary_str.slice(i * slice_length, 8).to_i(2).to_s
    mask_str += "." if i < 3
  end
  mask_str
end

url = "https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt"
puts "Downloading #{url}"
response = HTTP.get(url)
File.write("china-ip-list.txt", response.to_s) if response.code == 200

puts "Generating PAC file..."
file_content = File.read("LAN-IP-list.txt")
file_content += File.read("china-ip-list.txt")
ip_list_arr = []
file_content.each_line do |str|
  ip_arr = str.split('/')
  ip_arr[1] = calculate_subnet_mask(ip_arr[1].to_i)
  ip_list_arr.push(ip_arr)
end

ip_list_str = ip_list_arr.to_s
ip_list_str.gsub!("[[", "[\n    [")
ip_list_str.gsub!("],", "],\n   ")
ip_list_str.gsub!("]]", "]\n]")

pac_str = File.read("pac.template")
pac_str.gsub!("__IPLIST__", ip_list_str)
File.write("pac.txt", pac_str)
puts "pac.txt saved."

puts "Generating Surge3 config file..."
ip_rules = ""
File.read("china-ip-list.txt").each_line do |str|
  rule = "IP-CIDR,#{str.strip},DIRECT\n"
  ip_rules += rule
end
ip_rules.rstrip!

config_content = File.read("surge3.template")
config_content.gsub!("__IPRULES__", ip_rules)

ss_config = YAML.load(File.read("ss.yml"))
config_content.gsub!("__SERVER__", ss_config["server"])
config_content.gsub!("__PORT__", ss_config["port"])
config_content.gsub!("__ENCRYPTION__", ss_config["encryption"])
config_content.gsub!("__PASSWORD__", ss_config["password"])

File.write("surge3.conf", config_content)
puts "surge3.conf saved."

