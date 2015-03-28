app = lambda do |env|
  [200, { "Content-Type" => "text/plain" }, ["Hello Ruby\n"]]
end

run app
