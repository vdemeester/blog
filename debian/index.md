---
title: Debian
layout: page
body_class: red
group: navigation
---
{% include setup %}

This is the Debian related pages.

# Content tagged with Debian

{% for tag in site.tags %} 
{% if tag[0] == 'debian' %}
<ul>
{% assign pages_list = tag[1] %}  
{% include pages_list %}
</ul>
{% endif %}
{% endfor %}
