.PHONY : test test-coverage

test :
	testrb -b tests/*

test-coverage :
	rcov -x '\/jruby\/lib\/' -x '\/tests\/data\/' tests/*.rb