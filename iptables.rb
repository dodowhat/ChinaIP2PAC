require "etc"
require "json"
require "resolv"

IPSET_NAME = "china-ip-and-lan"
CHAIN_NAME = "SHADOWSOCKS"
LOCK_FILE = File.join(__dir__, "lock.json")

def init(ss_config_file)
  begin
    ss_config = JSON.parse(File.read(ss_config_file))
    raise "" if ss_config["server"].nil?
  rescue JSON::ParserError, RuntimeError
    puts "Error: Invalid shadowsocks config file."
  end

  puts "It may take a few minutes..."

  create_ipset
  setup_rules(ss_config)
  rules_up

  if !File.exist?(LOCK_FILE)
    lock_info = {
      ss_config_file: ss_config_file
    }
    File.write(LOCK_FILE, lock_info.to_json)
  end
end

def ipset_exists?
  result = system("ipset list #{IPSET_NAME}", out: File::NULL, err: File::NULL)
  if result.nil?
    puts "Please install 'ipset' package first."
    exit 127
  end
  result
end

def chain_exists?
  system("iptables -t nat -L #{CHAIN_NAME}", out: File::NULL, err: File::NULL)
end

def initiated?
  ipset_exists? || chain_exists?
end

def destroy_ipset
end

def create_ipset
  system("ipset create #{IPSET_NAME} hash:net")

  file_content = File.read(File.join(__dir__, "LAN-IP-list.txt"))
  file_content += File.read(File.join(__dir__, "china-ip-list.txt"))
  file_content.each_line do |str|
    system("ipset add #{IPSET_NAME} #{str.strip}")
  end
  system("sh -c 'ipset save > /etc/ipset.conf'")
end

def setup_rules(ss_config)
  system("iptables -t nat -N #{CHAIN_NAME}")
  ss_server = Resolv.getaddress(ss_config["server"])
  system("iptables -t nat -A #{CHAIN_NAME} -d #{ss_server} -j RETURN")
  system("iptables -t nat -A #{CHAIN_NAME} -p tcp -m set --match-set #{IPSET_NAME} dst -j RETURN")
  system("iptables -t nat -A #{CHAIN_NAME} -p tcp -j REDIRECT --to-port #{ss_config["local_port"].to_s}")
end

def save_rules
  system("sh -c 'iptables-save > /etc/iptables.rules'")
end

def rules_up?
  system("iptables -t nat -C OUTPUT -p tcp -j #{CHAIN_NAME}", err: File::NULL)
end

def rules_up
  system("iptables -t nat -A OUTPUT -p tcp -j #{CHAIN_NAME}") if !rules_up?
  save_rules
end

def rules_down
  system("iptables -t nat -D OUTPUT -p tcp -j #{CHAIN_NAME}") if rules_up?
  save_rules
end

def purge
  # purge_rules
  rules_down
  system("iptables -t nat -F #{CHAIN_NAME}")
  system("iptables -t nat -X #{CHAIN_NAME}")
  system("rm -rf /etc/iptables.rules")
  # destroy_ipset
  system("ipset destroy #{IPSET_NAME}", err: File::NULL)
  system("rm -rf /etc/ipset.conf")
end

if Etc.getpwuid.uid != 0
  puts "You need to run this script as root or using sudo"
  exit 1
end

case ARGV[0]
when "init"
  if initiated?
    puts "Already initiated."
    exit 99
  end
  if ARGV[1].nil?
    puts "Usage: sudo ruby iptables.rb init 'your-shadowsocks-config-filename'"
    exit 99
  end
  init(File.expand_path(ARGV[1]))
  puts "Done\n"
when "refresh"
  if !initiated?
    puts "Please run `sudo ruby iptables.rb init` first."
    exit 99
  end
  if File.exist?(LOCK_FILE)
    lock_info = JSON.parse(File.read(LOCK_FILE))
    purge
    init(lock_info["ss_config_file"])
  end
when "up"
  if !initiated?
    puts "Please run `sudo ruby iptables.rb init` first."
    exit 99
  end
  rules_up
when "down"
  if !initiated?
    puts "Please run `sudo ruby iptables.rb init` first."
    exit 99
  end
  rules_down
when "purge"
  if !initiated?
    puts "Please run `sudo ruby iptables.rb init` first."
    exit 99
  end
  purge
  system("rm -rf #{LOCK_FILE}")
else
  puts "Usage: sudo ruby iptables.rb [init|up|down|update|purge]"
end