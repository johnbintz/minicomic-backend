.PHONY : test test-coverage

test :
	testrb `find tests -name '*.rb'`

test-coverage :
	rcov -x '\/jruby\/lib\/' -x '\/tests\/data\/' `find tests -name '*.rb'`
	sed 's#<td class="left_align"><a href="<script>.html"><script></a></td>#<td></td>#' coverage/index.html > coverage/index.html.new
	mv coverage/index.html.new coverage/index.html
