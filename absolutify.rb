#!/usr/bin/ruby
# vim:set fleencoding=utf-8:

def absolutify(html, baseurl)
	return html
end

if __FILE__ == $0
	require 'test/unit'

	class TestAbsolutify < Test::Unit::TestCase
		def test_simple_img
			assert_equal(
				'<img src="http://example.org/foo/bar/baz.png">',
				absolutify('<img src="../foo/bar/baz.png">', 'http://example.org/hoge/')
			)
			assert_equal(
				"<img src='http://example.org/foo/bar/baz.png'>",
				absolutify("<img src='../foo/bar/baz.png'>", 'http://example.org/hoge/')
			)
			assert_equal(
				'<img src=http://example.org/foo/bar/baz.png>',
				absolutify('<img src=../foo/bar/baz.png>', 'http://example.org/hoge/')
			)
		end

		def not_yet_test_real_data
			srcs = Array.new
			srcs[0] = <<_END
<h3>ポケットに自由を</h3><div class="weather"><span class="weather">12:53現在<a href="http://weather.noaa.gov/weather/current/PHTO.html"><span class="condition">曇</span> <span class="temperature">28℃</span></a></span></div>
	<p><a href="http://zunda.freeshell.org/">Free Software Foundation</a>から郵便が届いていた。<p>先日メンバーになって、<a href="http://zunda.freeshell.org/blogs/membership/bootablemembership">ブートできる会員証</a>をお願いしていたものが届いたのでした。</p><p>本当なら払ったお金をぜんぶソフトウェアの自由のために使ってもらいたいところだけど、こういうグッズに興味もあるので。</p></p><div align="center"><img class="photo" src="../p/20090817_0.jpg" alt="gNewSense" title="gNewSense" width="256" height="192"></div><p>クレジットカードより小さい、ちょっと分厚いカードの端に端子がついていて外形寸法はクレジットカードの大きさになっている。これを挿して起動すると、ちょっと時間はかかるけれど、<a href="http://zunda.freeshell.org/">gNewSense</a>が起動してくれた。良いね。アクセスランプも光るよ!残念ながら<a href="http:/docomomo/">DocoMomo</a>よりだいぶ遅いけど財布に入れておくのには便利♪</a><p>郵便にはいくつかステッカーも入っていたので、早速N810に貼ってみました。</p><div align="center"><img class="photo" src="../p/20090817_1.jpg" alt="GNU/Linux inside!" title="GNU/Linux inside!" width="256" height="192"></div><p><a href="http://www.defectivebydesign.org/">Defective by Design</a>のステッカーはMacBookに貼っておきたいところだけど自重しておく。</p>
_END
			srcs[1] = <<_END
<h3>ポケットに自由を</h3><div class="weather"><span class="weather">12:53現在<a href="http://weather.noaa.gov/weather/current/PHTO.html"><span class="condition">曇</span> <span class="temperature">28℃</span></a></span></div>
<p><a href="/">Free Software Foundation</a>から郵便が届いていた。<p>先日メンバーになって、<a href="/blogs/membership/bootablemembership">ブートできる会員証</a>をお願いしていたものが届いたのでした。</p><p>本当なら払ったお金をぜんぶソフトウェアの自由のために使ってもらいたいところだけど、こういうグッズに興味もあるので。</p></p><div align="center"><img class="photo" src="http://zunda.freeshell.org/p/20090817_0.jpg" alt="gNewSense" title="gNewSense" width="256" height="192"></div><p>クレジットカードより小さい、ちょっと分厚いカードの端に端子がついていて外形寸法はクレジットカードの大きさになっている。これを挿して起動すると、ちょっと時間はかかるけれど、<a href="/">gNewSense</a>が起動してくれた。良いね。アクセスランプも光るよ!残念ながら<a href="http://zunda.freeshell.org/docomomo/">DocoMomo</a>よりだいぶ遅いけど財布に入れておくのには便利♪</a><p>郵便にはいくつかステッカーも入っていたので、早速N810に貼ってみました。</p><div align="center"><img class="photo" src="http://zunda.freeshell.org/p/20090817_1.jpg" alt="GNU/Linux inside!" title="GNU/Linux inside!" width="256" height="192"></div><p><a href="/">Defective by Design</a>のステッカーはMacBookに貼っておきたいところだけど自重しておく。</p>
_END
			dsts = srcs.map{|html| absolutify(html, 'http://zunda.freeshell.org/d/')}
			assert_equal(dsts[0], dsts[1])
		end
	end
end
