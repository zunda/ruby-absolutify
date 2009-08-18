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
	baseuri = URI.parse(URI.encode(baseurl))
	r = html.gsub(%r|<\S[^>]*/?>|) do |tag|
		type = tag.scan(/\A<(\S+)/)[0][0].downcase
		if attr = {'a' => 'href', 'img' => 'src'}[type]
			m = tag.match(%r|(.*#{attr}=)(['"]?)([^\2>]+?)\2(.*)|i)
			prefix = m[1] + m[2]
			location = m[3]
			postfix = m[2] + m[4]
			begin
				uri = URI.parse(location)
				if uri.relative?
					location = (baseuri + location).to_s
				elsif not uri.host
					location = (baseuri + uri.path).to_s
				end
				tag = prefix + location + postfix
			rescue URI::InvalidURIError
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

		def test_not_url
			assert_equal(
				'<img src="this is not a valid path">',
				absolutify('<img src="this is not a valid path">', 'http://example.org/foo/')
			)
		end

		def test_real_data
			srcs = Array.new
			srcs[0] = <<_END
<h3>ポケットに自由を</h3><div class="weather"><span class="weather">12:53現在<a href="http://weather.noaa.gov/weather/current/PHTO.html"><span class="condition">曇</span> <span class="temperature">28℃</span></a></span></div>
<p><a href="http://zunda.freeshell.org/">Free Software Foundation</a>から郵便が届いていた。<p>先日メンバーになって、<a href="http://zunda.freeshell.org/blogs/membership/bootablemembership">ブートできる会員証</a>をお願いしていたものが届いたのでした。</p><p>本当なら払ったお金をぜんぶソフトウェアの自由のために使ってもらいたいところだけど、こういうグッズに興味もあるので。</p></p><div align="center"><img class="photo" src="../p/20090817_0.jpg" alt="gNewSense" title="gNewSense" width="256" height="192"></div><p>クレジットカードより小さい、ちょっと分厚いカードの端に端子がついていて外形寸法はクレジットカードの大きさになっている。これを挿して起動すると、ちょっと時間はかかるけれど、<a href="http://zunda.freeshell.org/">gNewSense</a>が起動してくれた。良いね。アクセスランプも光るよ!残念ながら<a href="http:/docomomo/">DocoMomo</a>よりだいぶ遅いけど財布に入れておくのには便利♪</a><p>郵便にはいくつかステッカーも入っていたので、早速N810に貼ってみました。</p><div align="center"><img class="photo" src="../p/20090817_1.jpg" alt="GNU/Linux inside!" title="GNU/Linux inside!" width="256" height="192"></div><p><a href="http://zunda.freeshell.org/">Defective by Design</a>のステッカーはMacBookに貼っておきたいところだけど自重しておく。</p>
_END
			srcs[1] = <<_END
<h3>ポケットに自由を</h3><div class="weather"><span class="weather">12:53現在<a href="http://weather.noaa.gov/weather/current/PHTO.html"><span class="condition">曇</span> <span class="temperature">28℃</span></a></span></div>
<p><a href="/">Free Software Foundation</a>から郵便が届いていた。<p>先日メンバーになって、<a href="/blogs/membership/bootablemembership">ブートできる会員証</a>をお願いしていたものが届いたのでした。</p><p>本当なら払ったお金をぜんぶソフトウェアの自由のために使ってもらいたいところだけど、こういうグッズに興味もあるので。</p></p><div align="center"><img class="photo" src="http://zunda.freeshell.org/p/20090817_0.jpg" alt="gNewSense" title="gNewSense" width="256" height="192"></div><p>クレジットカードより小さい、ちょっと分厚いカードの端に端子がついていて外形寸法はクレジットカードの大きさになっている。これを挿して起動すると、ちょっと時間はかかるけれど、<a href="/">gNewSense</a>が起動してくれた。良いね。アクセスランプも光るよ!残念ながら<a href="http://zunda.freeshell.org/docomomo/">DocoMomo</a>よりだいぶ遅いけど財布に入れておくのには便利♪</a><p>郵便にはいくつかステッカーも入っていたので、早速N810に貼ってみました。</p><div align="center"><img class="photo" src="http://zunda.freeshell.org/p/20090817_1.jpg" alt="GNU/Linux inside!" title="GNU/Linux inside!" width="256" height="192"></div><p><a href="/">Defective by Design</a>のステッカーはMacBookに貼っておきたいところだけど自重しておく。</p>
_END
			dsts = srcs.map{|html| absolutify(html, 'http://zunda.freeshell.org/d/')}
			#puts
			#puts dsts[0]
			#puts dsts[1]
			assert_equal(dsts[0], dsts[1])
		end
	end
end
