<% mark = "0x" + (Integer(service)|0x1000).to_s(16) %>
/sbin/ip rule show |grep -q "fwmark <%= mark %>" || /sbin/ip rule add prio 100 fwmark <%= mark %> table 100
<% virtual_ips.each do |vip| %>
/sbin/iptables -t mangle -A PREROUTING --protocol tcp -m multiport --destination <%= vip %> --dports <%= ports.join(",") %> -j MARK --set-mark <%= mark %><% end %>
