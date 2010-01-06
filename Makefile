.PHONY : test test-coverage

test :
	testrb `find tests -name '*.rb'`

test-coverage :
	rcov -x '\/jruby\/lib\/' -x '\/tests\/data\/' `find tests -name '*.rb'`