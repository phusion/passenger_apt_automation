require 'socket'

def sh(command)
  output = IO.popen("#{command} 2>&1", "r") do |io|
    io.read
  end
  if $?.exitstatus != 0
    raise "Command failed: #{command}\n" +
      "Output:\n#{output}"
  end
end

def ping_socket(socket_domain, sockaddr)
  begin
    socket = Socket.new(socket_domain, Socket::Constants::SOCK_STREAM, 0)
    begin
      socket.connect_nonblock(sockaddr)
    rescue Errno::ENOENT, Errno::EINPROGRESS, Errno::EAGAIN, Errno::EWOULDBLOCK
      if select(nil, [socket], nil, 0.1)
        begin
          socket.connect_nonblock(sockaddr)
        rescue Errno::EISCONN
        rescue Errno::EINVAL
          if RUBY_PLATFORM =~ /freebsd/i
            raise Errno::ECONNREFUSED
          else
            raise
          end
        end
      else
        raise Errno::ECONNREFUSED
      end
    end
    true
  rescue Errno::ECONNREFUSED, Errno::ENOENT
    false
  ensure
    socket.close if socket
  end
end

def ping_tcp_socket(hostname, port)
  sockaddr = Socket.pack_sockaddr_in(port, hostname)
  begin
    ping_socket(Socket::Constants::AF_INET, sockaddr)
  rescue Errno::EAFNOSUPPORT
    ping_socket(Socket::Constants::AF_INET6, sockaddr)
  end
end

def eventually(deadline_duration = 10, check_interval = 0.05)
  deadline = Time.now + deadline_duration
  while Time.now < deadline
    if yield
      return
    else
      sleep(check_interval)
    end
  end
  raise "Time limit exceeded"
end
