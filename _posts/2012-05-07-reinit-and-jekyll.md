---
layout: post
category : me
tags : [intro, jekyll]
body_class : gray
---
{% include setup %}

Two weeks ago, my _online_ personal server has been attacked and, somehow, died. I'm in the process
of re-installation of it but I'm going to hardened a bit the security on it. Anyway, this crash meant
that every piece of site I maintain has been down. That's why I moved this _identity site_ on the
github pages, using a CNAME ; That way I can crash as much as I want my server(s), this page should
still be up for a while.

And I'm switching on Jekyll for this website as It is supported by Github page, easy to use and easy
to deploy elsewhere (if one day I want to move from Github).

The rest of the post is going to be used as a *sandbox* post to test the site styles.

> This is a blockquote with two paragraphs. Lorem ipsum dolor sit amet,
> consectetuer adipiscing elit. Aliquam hendrerit mi posuere lectus.
> Vestibulum enim wisi, viverra nec, fringilla in, laoreet vitae, risus.
>  
> Donec sit amet nisl. Aliquam semper ipsum sit amet velit. Suspendisse
> id sem consectetuer libero luctus adipiscing.
> 

## Highlight

{% highlight ruby %}
def foo
  puts 'foo'
end
{% endhighlight %}

Some bash script…

{% highlight bash %}
#!/bin/bash
update_gems() {
    echo "Update gems for all versions ? (y/N)"
    read UPDATE_GEMS
    test -z "${UPDATE_GEMS}" && UPDATE_GEMS="n"
    if test "${UPDATE_GEMS}" = "y"; then
        for version in `ls --color=never $HOME/.rbenv/versions`; do
            echo "Updating ${version%/}"
            RBENV_VERSION="${version%/}" rbenv exec gem update
            RBENV_VERSION="${version%/}" rbenv exec gem install bundler
        done
    fi
}

update_gems
{% endhighlight %}

