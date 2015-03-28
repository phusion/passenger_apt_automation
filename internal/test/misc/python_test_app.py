def application(environ, start_response):
	start_response('200 OK', [('Content-Type', 'text/plain')])
	return [str('Hello Python\n')]
