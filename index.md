---
title: Hi, I'm Vincent Demeester, a <em>french</em> developer, sysadmin, <abbr title="who does all kinds of work"> factotum</abbr> and <span class="fan"><abbr title="as in free speek">free</abbr>-software <abbr title="You could say Evangelist">fan</abbr></span>.
layout: page
tagline: Supporting tagline
bodyClass: home
---
{% include setup %}

<p>Since 2008, I'm working at <a href="http://nextep.net">nextep</a> as a Java Developer, and since mid-2009 I've been <em>promoted</em> as the core developer and the <em>core</em> sysadmin <code>\o/</code>. Working there is also a way to learn and understand the concepts and issues related to energy.</p>
<p>I'm graduated from both <a href="http://www.ece.fr">ECE (École Centrale d'Électronique)</a> and <a href="http://www.uio.no/english/">UiO (University i Oslo)</a>.</p>
<p>I develop in <a href="http://java.oracle.com">Java</a> and <a href="http://ruby-lang.org">Ruby</a> ; I'm learning <a href="http://haskell.org">Haskell</a> and wishing to have time to learn <a href="http://clojure.org">Clojure</a> and <a href="http://www.scala-lang.org">Scala</a>. I'm a GNU/Linux user, mainly <a href="http://www.debian.org">Debian GNU/Linux</a> and <a href="http://www.archlinux.org">Archlinux</a>. I no longer use or need Microsoft<sup>®</sup> Windows<sup>®</sup> but I'm, <abbr title="means once in a year or something like that">sometimes</abbr>, using Mac OS X at work (but you don't want to know how low is Apple in my mind).</p>
<p>I'm a <a href="https://fellowship.fsfe.org/">FSFE fellow</a> since 2010 (and previously a FSF fellow), <a href="http://www.framasoft.net">Framasoft</a> and <a href="http://lqdn.fr">La Quadrature du Net</a> supporter/donator.</p>

# Contact

<dl>
<dt>Email</dt>
<dd class="mail">vin<span class="zzz">SPAM</span>cent<span class="zzz">AT</span>@dem<span class="zzz">SPAM</span>eester<span class="zzz">DOT</span>.fr</dd>
<dd class="gnupg"><a href="VincentDemeester.asc">5860 2A88</a></dd>
<dt>Instant Messaging</dt>
<dd class="jabber"><a href="xmpp:vdemeester@jabber.fsfe.org">
vdemeester@<span style="color: #d9531e">jabber</span>.<span style="color: rgb(0, 153, 0);">fsfe.org</span></a></dd>
<dd class="irc">vdemeester@irc.freenode.net
 <a href="irc://irc.freenode.net:6667/fsfeurope">#fsfeurope</a>
 <a href="irc://irc.freenode.net:6667/openweb">#openweb</a>
 <a href="irc://irc.freenode.net:6667/debianfr">#debianfr</a></dd>
<dd class="irc">vdemeester@irc.oftc.net
 <a href="irc://irc.oftc.net:6667/vcs-home">#vcs-home</a>
 <a href="irc://irc.oftc.net:6667/debian-fr">#debian-fr</a></dd>
</dl>
<br />

# Posts

<ul class="posts">
  {% for post in site.posts limit:3 %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>
