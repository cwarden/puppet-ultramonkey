virtual=<%= Integer(service)|0x1000 %><% real_ips.each do |real_server| %>
	real=<%= real_server %> gate<% end %>
	service=http
	request="ldirector.html"
	receive="Test Page"
	scheduler=rr
	checktype=negotiate
