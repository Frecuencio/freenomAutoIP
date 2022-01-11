#!/usr/bin/env ruby
# Ruby freeNom update IP
#
# Created by: Carlos Martín Arnillas
# Version 0.1
# Last update: 11/01/2022
# License: GNU General Public License v3.0
#

require 'net/http'
require 'yaml'
require 'logger'


class FreeNomUpdater
    def initialize
        @USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36'
        @BASE_PORT = 443
        @MAX_GET_REDIRECTS = 5
        # URL VARS
        @BASE_URL = 'my.freenom.com'
        @CLIENT_AREA_URL = '/clientarea.php'
        @LOGIN_URL = '/dologin.php'
        @LOGOUT_URL = '/logout.php'
        @IP_CHECK_URL = 'https://api.ipify.org'
        @public_ip = nil
        # CONNECTION
        @httpConn = Net::HTTP.new(@BASE_URL, @BASE_PORT)
        @httpConn.use_ssl = true
        @token = nil
        # COOKIE JAR
        @cookies = nil
        # YAML FILE
        @YAML_FILE = ENV['FNIP_CONFIG'] || File.join(__dir__, 'config.yml')
        @saved_config = nil

        # LOGGER
        @logger = Logger.new(ENV['FNIP_LOG'] || STDOUT) # TODO: Check env vars Logger.new('foo.log', 10, 1024000)
        @logger.level = ENV['FNIP_LOGLEVEL'] || Logger::INFO

        # LOAD CONFIG FILE
        self.loadYamlFile
    end

    def buildQueryString(data)
        URI.encode_www_form(data)
    end

    # Dirty cookie jar implementation
    def storeCookies(cookies)
        if cookies.nil?
            return
        end

        cookies_array = Array.new
        cookies.each { | cookie |
            cookies_array.push(cookie.split('; ')[0])
        }
        @cookies = cookies_array.join('; ')
    end

    # GET request, with custom User-Agent, controlling redirects and storing cookies
    def getWithCookies(url:, redirectNo: 0, data: nil)
        url = (data.nil?) ? url : url + '?' + self.buildQueryString(data)
        @logger.debug("GET: #{url}")
        res = @httpConn.get(url, 
                (@cookies.nil?) ? {'User-Agent' => @USER_AGENT} 
                    : { 'User-Agent' => @USER_AGENT, 'Cookie' => @cookies }
        )        
        self.storeCookies(res.get_fields('set-cookie'))
        # Follow redirects
        if res.code == '302' && res['location'] && redirectNo < @MAX_GET_REDIRECTS
            res = getWithCookies(url: '/' + res['location'], redirectNo: redirectNo+=1)
        elsif res.code == '302' && redirectNo >= @MAX_GET_REDIRECTS 
            # Stop loop redirect
            @logger.error("Max GET redirects reached (#{redirectNo}): #{@BASE_URL}#{url}")
            raise "Max GET redirects reached (#{redirectNo})"
        end
        return res
    end

    # POST request with custom User-Agent and Cookies implementation
    def postWithCookies(url:, data:'')
        @logger.debug("POST: #{url}  [#{data}]")
        res = @httpConn.post(url, data, {'User-Agent' => @USER_AGENT,
                                         'Cookie' => (@cookies.nil?) ? '' : @cookies,
                                         'Content-type' => 'application/x-www-form-urlencoded',
                                         'Referer' => @BASE_URL+url
                                        }
        )
        self.storeCookies(res.get_fields('set-cookie'))
        return res
    end

    # Parse csrf token balue
    def getTokenValue(body)
        res = /<input type="hidden" name="token" value="[a-zA-Z0-9]*" \/>/.match(body)
        if res.nil?
            @logger.error("Token not found")
            raise "Error: token not found"
        end
        @token = res[0][41..-5]
        @logger.debug("New token: #{@token}")
    end

    # Used to get first csrf token
    def visitLogin
        response = self.getWithCookies(url: @CLIENT_AREA_URL)
        self.getTokenValue(response.body)
    end

    def doLogin
        query = self.buildQueryString({'token' => @token, 'username' => @saved_config['username'], 'password' => @saved_config['password']})
        response = self.postWithCookies(url: @LOGIN_URL, data:query)
        if response['location'] == '/clientarea.php?incorrect=true'
            @logger.error("Incorrect login")
            raise 'Incorrect login data'
        end
    end

    # Used to get csrf token between post requests
    def visitManageDNS(site)
        response = self.getWithCookies(url: @CLIENT_AREA_URL, 
                                       data: {'managedns' => site['name'],
                                              'domainid' => site['domainid']})
        self.getTokenValue(response.body)
    end

    def modifyRecords(site)
        queryVars = {'dnsaction' => 'modify',
                     'token' => @token}
        # Parse config file
        site['records'].each do |key, record|
            record.each do |action, val|
                val || val = ''
                (val == '_IP_')? val = @public_ip : val = "#{val}"
                queryVars["records[#{key}][#{action}]"] = val
            end
        end
        self.postWithCookies(url: @CLIENT_AREA_URL + "?" + self.buildQueryString({'managedns' => site['name'],
            'domainid' => site['domainid']}), data: self.buildQueryString(queryVars))
    end

    def doLogout
        self.getWithCookies(url: @LOGOUT_URL)
    end

    def ipChanged?
        @public_ip = Net::HTTP.get URI @IP_CHECK_URL
        if @saved_config['lastIp'] != @public_ip
            @logger.info("IP changed! #{@saved_config['lastIp']} -> #{@public_ip}")
            return true
        end
        return false
    end 

    def loadYamlFile()
        if !File.exist?(@YAML_FILE)
            @logger.error("Config file doesn't exists")
            raise "COULD NOT OPEN FILE"
        end
        @saved_config = YAML::load_file(@YAML_FILE)
    end

    def saveYamlFile
        @saved_config['lastIp'] = @public_ip
        File.open(@YAML_FILE, 'w') {|f| f.write @saved_config.to_yaml }
    end

    def run
        if !self.ipChanged?
            @logger.info("ip not changed (#{@public_ip})")
            return
        end
        self.visitLogin
        self.doLogin
        
        @saved_config['sites'].each do |k, site|
            self.visitManageDNS(site) 
            self.modifyRecords(site)
        end

        self.saveYamlFile

        self.doLogout
    end
end


if __FILE__ == $0
    freeNom = FreeNomUpdater.new()
    freeNom.run
end
