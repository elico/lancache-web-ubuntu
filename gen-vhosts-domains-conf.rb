#!/usr/bin/env ruby

require "open-uri"

def validDomain(domain)
        begin
        uri = URI.parse("http://#{domain}/")
        if uri.kind_of?(URI::HTTP) or uri.kind_of?(URI::HTTPS)
                return true
        end
        rescue
                return false
        end
        return false
end

vhosts = %x[ ls /usr/local/nginx/vhosts-enabled/*conf ].lines
#vhosts = [ "lancache-microsoft" ]

vhosts.each do |vhost|
	vhost = vhost.chomp.gsub("/usr/local/nginx/vhosts-enabled/" ,"").gsub(".conf", "")
	domainsList = []
	if !File.exists?("/srv/#{vhost}.domains-txt")
		puts "File: /srv/#{vhost}.domains-txt do not exist!"
		next
	end
	lines = File.readlines("/srv/#{vhost}.domains-txt")
	lines.each do |line|
	        next if line.index('#')
	        domLine = line.chomp.strip
	        if validDomain(domLine)
	                if domLine.end_with?(".")
	                        domainsList << domLine.chop
	                else
	                        domainsList << domLine
	                end
	        end
	end
	domainsListStr = ""
	domainsList.each do |dom|
		domainsListStr << "\tserver_name #{dom};\n"
	end
	cmd = "echo '#{domainsListStr}'> /usr/local/nginx/vhosts-domains/#{vhost}.conf"
	%x[ #{cmd} ]
	puts "Created: /usr/local/nginx/vhosts-domains/#{vhost}.conf"
end

