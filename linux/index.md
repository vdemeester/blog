---
title: GNU/Linux
layout: page
bodyClass: red
group: navigation
---
{% include setup %}

This is the GNU/Linux related pages.

# Debian

* [Debian 6.0 Squeeze notes](debian/squeeze-notes.html)
* [Gitolite on Debian](gitolite-notes.html)

# Content tagged with linux

{% for tag in site.tags %} 
{% if tag[0] == 'linux' %}
<ul>
{% assign pages_list = tag[1] %}  
{% include pages_list %}
</ul>
{% endif %}
{% endfor %}

# Todo(s)

- Debian
  - Installation notes (on thinkpad, eee pcs and servers)
  - Fail2ban notes (git-daemon, …)
  - Xen installation & notes
- LXC : projects & notes
