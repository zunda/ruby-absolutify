#!/usr/bin/ruby
# vim:set fileencoding=utf-8:
#
# absolutify.rb - a method to modify relative URIs into absolute ones
#
# Copyright 2009 zunda <zunda at freeshell.org>
# 
# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work under the terms
# of GPL version 2 or later.
#
require 'uri'

def absolutify(html, baseurl)
	@@_absolutify_attr_regexp ||= Hash.new
	baseuri = URI.parse(URI.encode(baseurl))
	r = html.gsub(%r|<\S[^>]*/?>|) do |tag|
		type = tag.scan(/\A<(\S+)/)[0][0].downcase
		if attr = {'a' => 'href', 'img' => 'src'}[type]
			@@_absolutify_attr_regexp[attr] ||= %r|(.*#{attr}\s*=\s*)(['"]?)([^\2>]+?)(\2.*)|im
			m = tag.match(@@_absolutify_attr_regexp[attr])
			if m
				prefix = m[1] + m[2]
				location = m[3]
				postfix = m[4]
				begin
					uri = URI.parse(location)
					if uri.relative?
						location = (baseuri + location).to_s
					elsif not uri.host
						path = uri.path
						path += '?' + uri.query if uri.query
						path += '#' + uri.fragment if uri.fragment
						location = (baseuri + path).to_s
					end
					tag = prefix + location + postfix
				rescue URI::InvalidURIError
				rescue ArgumentError
				end
			end
		end
		tag
	end
	return r
end

if __FILE__ == $0
	require 'test/unit'

	class TestAbsolutify < Test::Unit::TestCase
		def test_encode
			assert_equal(
				'<img src="http://example.org/f%22oo/bar/baz.png">',
				absolutify('<img src="bar/baz.png">', 'http://example.org/f"oo/')
			)
		end

		def test_with_host_query_and_fragment
			assert_equal(
				'<img src="http://example.org/bar/baz.png?muga#here">',
				absolutify('<img src="http:/bar/baz.png?muga#here">', 'http://example.org/foo/')
			)
			assert_equal(
				'<img src="http://example.org/bar/baz.png?muga">',
				absolutify('<img src="http:/bar/baz.png?muga">', 'http://example.org/foo/')
			)
			assert_equal(
				'<img src="http://example.org/bar/baz.png#here">',
				absolutify('<img src="http:/bar/baz.png#here">', 'http://example.org/foo/')
			)
		end

		def test_with_query_and_fragment
			assert_equal(
				'<img src="http://example.org/foo/bar/baz.png?muga#here">',
				absolutify('<img src="bar/baz.png?muga#here">', 'http://example.org/foo/')
			)
		end

		def test_partially_absolute
			assert_equal(
				'<img src="http://example.org/foo/bar/baz.png">',
				absolutify('<img src="http:/foo/bar/baz.png">', 'http://example.org/foo/')
			)
		end

		def test_attributes
			assert_equal(
				'<img class="photo" src="http://example.org/foo/bar/baz.png" alt="baz">',
				absolutify('<img class="photo" src="bar/baz.png" alt="baz">', 'http://example.org/foo/')
			)
		end

		def test_parent
			assert_equal(
				'<img src="http://example.org/foo/bar/baz.png">',
				absolutify('<img src="../bar/baz.png">', 'http://example.org/foo/hoge/')
			)
		end

		def test_capitalized
			assert_equal(
				'<IMG SRC="http://example.org/foo/bar/baz.png">',
				absolutify('<IMG SRC="bar/baz.png">', 'http://example.org/foo/')
			)
		end

		def test_simple_img
			assert_equal(
				'<img src="http://example.org/foo/bar/baz.png">',
				absolutify('<img src="bar/baz.png">', 'http://example.org/foo/')
			)
			assert_equal(
				"<img src='http://example.org/foo/bar/baz.png'>",
				absolutify("<img src='bar/baz.png'>", 'http://example.org/foo/')
			)
			assert_equal(
				'<img src=http://example.org/foo/bar/baz.png>',
				absolutify('<img src=bar/baz.png>', 'http://example.org/foo/')
			)
		end

		def test_img_with_other_tags
			assert_equal(
				'<p><img class="right" src="http://example.org/foo/bar/baz.png">hello world</p>',
				absolutify('<p><img class="right" src="bar/baz.png">hello world</p>', 'http://example.org/foo/')
			)
		end

		def test_simple_a
			assert_equal(
				'<a href="http://example.org/foo/bar/baz.png">',
				absolutify('<a href="bar/baz.png">', 'http://example.org/foo/')
			)
			assert_equal(
				"<a href='http://example.org/foo/bar/baz.png'>",
				absolutify("<a href='bar/baz.png'>", 'http://example.org/foo/')
			)
			assert_equal(
				'<a href=http://example.org/foo/bar/baz.png>',
				absolutify('<a href=bar/baz.png>', 'http://example.org/foo/')
			)
		end

		def test_new_line_inside_tag
			assert_equal(
				'<a href="http://www.example.com/foo/"><img class="left"
src="http://www.example.com/foo.png"></a>
',
				absolutify('<a href="http://www.example.com/foo/"><img class="left"
src="http://www.example.com/foo.png"></a>
', 'http://example.org/foo/')
			)
		end

		def test_white_space_around_equal_sign
			assert_equal(
				'<img class = "left" src = "http://www.example.com/foo.png"></a>',
				absolutify('<img class = "left" src = "http://www.example.com/foo.png"></a>', 'http://example.org/foo/')
			)
			assert_equal(
				'<img class = "left" src = "http://example.org/foo/bar.png"></a>',
				absolutify('<img class = "left" src = "bar.png"></a>', 'http://example.org/foo/')
			)
		end

		def test_without_attributes_to_be_replaced
			assert_equal(
				'<a name="2009/07/19">foo</a>',
				absolutify('<a name="2009/07/19">foo</a>', 'http://example.org/foo/')
			)
		end

		def test_not_url
			assert_equal(
				'<img src="this is not a valid path">',
				absolutify('<img src="this is not a valid path">', 'http://example.org/foo/')
			)
		end

		# https://github.com/tdiary/tdiary-core/pull/213
		def test_invalid_url
			assert_equal(
				'fuga<a href="foo:bar://baz">hoge</a>moga',
				absolutify('fuga<a href="foo:bar://baz">hoge</a>moga', 'http://example.org/foo/')
			)
		end

		def test_real_data
			srcs = Array.new
			srcs[0] = <<_END
<h3>ãã±ããã«èªç±ã</h3><div class="weather"><span class="weather">12:53ç¾å¨<a href="http://weather.noaa.gov/weather/current/PHTO.html"><span class="condition">æ</span> <span class="temperature">28â</span></a></span></div>
<p><a href="http://zunda.freeshell.org/">Free Software Foundation</a>ããéµä¾¿ãå±ãã¦ããã<p>åæ¥ã¡ã³ãã¼ã«ãªã£ã¦ã<a href="http://zunda.freeshell.org/blogs/membership/bootablemembership">ãã¼ãã§ããä¼å¡è¨¼</a>ããé¡ããã¦ãããã®ãå±ããã®ã§ããã</p><p>æ¬å½ãªãæã£ããéãããã¶ã½ããã¦ã§ã¢ã®èªç±ã®ããã«ä½¿ã£ã¦ãããããã¨ããã ãã©ãããããã°ããºã«èå³ãããã®ã§ã</p></p><div align="center"><img class="photo" src="../p/20090817_0.jpg" alt="gNewSense" title="gNewSense" width="256" height="192"></div><p>ã¯ã¬ã¸ããã«ã¼ãããå°ãããã¡ãã£ã¨ååãã«ã¼ãã®ç«¯ã«ç«¯å­ãã¤ãã¦ãã¦å¤å½¢å¯¸æ³ã¯ã¯ã¬ã¸ããã«ã¼ãã®å¤§ããã«ãªã£ã¦ããããããæ¿ãã¦èµ·åããã¨ãã¡ãã£ã¨æéã¯ãããããã©ã<a href="http://zunda.freeshell.org/">gNewSense</a>ãèµ·åãã¦ããããè¯ãã­ãã¢ã¯ã»ã¹ã©ã³ããåãã!æ®å¿µãªãã<a href="http:/docomomo/">DocoMomo</a>ããã ãã¶éããã©è²¡å¸ã«å¥ãã¦ããã®ã«ã¯ä¾¿å©âª</a><p>éµä¾¿ã«ã¯ããã¤ãã¹ããã«ã¼ãå¥ã£ã¦ããã®ã§ãæ©éN810ã«è²¼ã£ã¦ã¿ã¾ããã</p><div align="center"><img class="photo" src="../p/20090817_1.jpg" alt="GNU/Linux inside!" title="GNU/Linux inside!" width="256" height="192"></div><p><a href="http://zunda.freeshell.org/">Defective by Design</a>ã®ã¹ããã«ã¼ã¯MacBookã«è²¼ã£ã¦ããããã¨ããã ãã©èªéãã¦ããã</p>
_END
			srcs[1] = <<_END
<h3>ãã±ããã«èªç±ã</h3><div class="weather"><span class="weather">12:53ç¾å¨<a href="http://weather.noaa.gov/weather/current/PHTO.html"><span class="condition">æ</span> <span class="temperature">28â</span></a></span></div>
<p><a href="/">Free Software Foundation</a>ããéµä¾¿ãå±ãã¦ããã<p>åæ¥ã¡ã³ãã¼ã«ãªã£ã¦ã<a href="/blogs/membership/bootablemembership">ãã¼ãã§ããä¼å¡è¨¼</a>ããé¡ããã¦ãããã®ãå±ããã®ã§ããã</p><p>æ¬å½ãªãæã£ããéãããã¶ã½ããã¦ã§ã¢ã®èªç±ã®ããã«ä½¿ã£ã¦ãããããã¨ããã ãã©ãããããã°ããºã«èå³ãããã®ã§ã</p></p><div align="center"><img class="photo" src="http://zunda.freeshell.org/p/20090817_0.jpg" alt="gNewSense" title="gNewSense" width="256" height="192"></div><p>ã¯ã¬ã¸ããã«ã¼ãããå°ãããã¡ãã£ã¨ååãã«ã¼ãã®ç«¯ã«ç«¯å­ãã¤ãã¦ãã¦å¤å½¢å¯¸æ³ã¯ã¯ã¬ã¸ããã«ã¼ãã®å¤§ããã«ãªã£ã¦ããããããæ¿ãã¦èµ·åããã¨ãã¡ãã£ã¨æéã¯ãããããã©ã<a href="/">gNewSense</a>ãèµ·åãã¦ããããè¯ãã­ãã¢ã¯ã»ã¹ã©ã³ããåãã!æ®å¿µãªãã<a href="http://zunda.freeshell.org/docomomo/">DocoMomo</a>ããã ãã¶éããã©è²¡å¸ã«å¥ãã¦ããã®ã«ã¯ä¾¿å©âª</a><p>éµä¾¿ã«ã¯ããã¤ãã¹ããã«ã¼ãå¥ã£ã¦ããã®ã§ãæ©éN810ã«è²¼ã£ã¦ã¿ã¾ããã</p><div align="center"><img class="photo" src="http://zunda.freeshell.org/p/20090817_1.jpg" alt="GNU/Linux inside!" title="GNU/Linux inside!" width="256" height="192"></div><p><a href="/">Defective by Design</a>ã®ã¹ããã«ã¼ã¯MacBookã«è²¼ã£ã¦ããããã¨ããã ãã©èªéãã¦ããã</p>
_END
			dsts = srcs.map{|html| absolutify(html, 'http://zunda.freeshell.org/d/')}
			#puts
			#puts dsts[0]
			#puts dsts[1]
			assert_equal(dsts[0], dsts[1])
		end
	end
end
