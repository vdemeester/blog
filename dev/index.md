---
title: Development
layout: page
body_class: gray
group: navigation
---
{% include setup %}

This is the Development related pages (Java, Ruby, …).

# Content tagged with Debian

{% for tag in site.tags %} 
{% if tag[0] == 'debian' %}
<ul>
{% assign pages_list = tag[1] %}  
{% include pages_list %}
</ul>
{% endif %}
{% endfor %}
