#!/usr/bin/ruby
# The purpose of this script is to check the size of the queues to central.
# It uses the Expect module to log in to the server and go to monitor upload
# queue.

require 'pty'
require 'expect'

host = ARGV[0]
login = ARGV[1]
pass = ARGV[2]
site = ARGV[3]
ARGV[4] ? timeout = ARGV[4].to_i : timeout = 5

def check_queue(host, login, pass, site, timeout) # TODO: return something useful on timeouts
  # Pattern to return the site and number of items in the queue
  # Watch out for [[:cntrl:]] which matches an invisible character in the output
  site_pat = %r/#{site}[[:cntrl:]]\[\d+;\d+H(\d+)/io
  size = ''
  PTY.spawn("ssh #{login}@#{host}") do |ssh_out, ssh_in|
    ssh_out.sync = true
    ssh_out.expect(/password:/, timeout) { |r| ssh_in.puts pass }
    ssh_out.expect(/Choose one.*M.*/, timeout) { |r| ssh_in.puts "m" }
    ssh_out.expect(/Choose one.*M.*/, timeout) { |r| ssh_in.puts "m" }
    ssh_out.expect(/Choose one.*U.*/, timeout) { |r| ssh_in.puts "u" }
    #Process the final screen where our numbers are
    ssh_out.expect(/Get CURRENT data/, timeout * 2) do |output|
      output.each do |line|
        queue = site_pat.match(line)
        queue ? size = queue[1] : abort("The pattern did not return a value. Check your site code")
      end
    end
    # Exits the script. TODO: There may be a better way to clean up the connection
    ssh_out.expect(/Choose one.*Q/, timeout) { |r| ssh_in.puts "q" }
    ssh_out.expect(/Choose one.*Q/, timeout) { |r| ssh_in.puts "q" }
    ssh_out.expect(/Choose one.*Q/, timeout) { |r| ssh_in.puts "q" }
    ssh_out.expect(/Choose one.*X/, timeout) { |r| ssh_in.puts "x" }
  end
  size
end

def help()
  STDOUT.flush
  STDOUT.puts <<-EOF
  A ruby utility to check the status of upload queues for an InnReach system. This
  script will return an integer
  
  Usage:
  check_queue host login pass site [timeout]
  
  Required Parameters:
  
  host: The Millennium host to connect to
  
  login: A username that will open Millennium telnet on host
  
  pass: Password associated with login
  
  site: The sitecode to check
  
  Optional Parameters
  timeout: An optional timeout value in seconds for processing of individual screens. 
     Default: 5
  EOF
end

if ARGV.length < 4 
  help
  abort("Missing parameters")
end

puts check_queue(host, login, pass, site, timeout)
