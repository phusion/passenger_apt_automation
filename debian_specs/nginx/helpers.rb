require File.absolute_path(File.dirname(__FILE__)) + '/../passenger/helpers'

def localstatedir
  case distribution_class
  when :ubuntu
    if is_distribution?("<= quantal")
      "/var/run"
    else
      "/run"
    end
  when :debian
    if is_distribution?("<= wheezy")
      "/var/run"
    else
      "/run"
    end
  else
    raise "Unsupported distribution class"
  end
end

def default_document_root
  case distribution_class
  when :ubuntu
    if is_distribution?("<= quantal")
      "/usr/share/nginx/www"
    elsif is_distribution?("<= utopic")
      "/usr/share/nginx/html"
    else
      "/var/www/html"
    end
  when :debian
    if is_distribution?("<= wheezy")
      "/usr/share/nginx/www"
    else
      "/var/www/html"
    end
  else
    raise "Unsupported distribution class"
  end
end
