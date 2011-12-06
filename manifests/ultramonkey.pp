# TODO - right now lb1 is always the primary node.  we should be able to
# split up services across load balancers for an active-active setup
class loadbalancer inherits server {
	file { 
		["/etc/ha.d/ldirectord.cf.d", "/etc/ha.d/lvs-services.d"]:
			ensure => directory;
		"/etc/ha.d/lvs-services.d/00-start":
			backup => false,
			notify => Mergesnippets["/etc/ha.d/lvs-services"],
			content => "#!/bin/sh
/sbin/iptables -t mangle -F
/sbin/ip route show table 100 | grep -q '^local' || /sbin/ip route add local 0/0 dev lo table 100
";
		"/etc/ha.d/haresources":
			content => "lb1	ldirectord::ldirectord.cf LVSSyncDaemonSwap::master IPaddr2::192.168.15.51/24/eth0 IPaddr2::192.168.150.3/24/eth1\n",
			backup => false;
		"/etc/ha.d/ldirectord.cf.d/00-defaults":
			backup => false,
			notify => Mergesnippets["/etc/ha.d/ldirectord.cf"],
			content => "checktimeout=10
checkinterval=10
autoreload=yes
logfile=\"/var/log/ldirectord.log\"
quiescent=no
";
		"/etc/network/if-pre-up.d/lvs-services":
			source => "/etc/ha.d/lvs-services",
			backup => false,
			notify => Exec[load-lvs],
			mode => 750,
			require => Mergesnippets["/etc/ha.d/lvs-services"];
	}

	remotefile {
		"/etc/apt/sources.list": source => "/system/ultramonkey/sources.list", mode => 644;
		"/etc/network/if-pre-up.d/firewall": source => "/system/ultramonkey/firewall", mode => 750, notify => Exec["load-firewall"];
	}

	Remotefile["/etc/sysctl.conf"] { source => "/system/ultramonkey/sysctl.conf" }

	exec {
		load-firewall: command => "/etc/network/if-pre-up.d/firewall", refreshonly => true;
		load-lvs: command => "/etc/network/if-pre-up.d/lvs-services", refreshonly => true;
	}

	service { heartbeat:
		ensure => running,
		restart => "/etc/init.d/heartbeat restart"
	}

	mergesnippets { "/etc/ha.d/ldirectord.cf": }
	mergesnippets { "/etc/ha.d/lvs-services": }
}

define lbservice($virtual_ips, $real_ips, $ports = [80], $primary_server = lb1) {
	$service = $name
	file {
		"/etc/ha.d/ldirectord.cf.d/$service":
			content => template("ldirectord.cf.snippet.rb"),
			notify => Mergesnippets["/etc/ha.d/ldirectord.cf"],
			backup => false;
		"/etc/ha.d/lvs-services.d/$service":
			content => template("lvs-service.snippet.rb"),
			notify => Mergesnippets["/etc/ha.d/lvs-services"],
			backup => false;
	}
}
