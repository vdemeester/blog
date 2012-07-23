---
layout: post
category : developement
tags : [maven, java, git, gitflow, release]
lang : fr
bodyClass : gray
---
{% include setup %}

I like a lot the [gitflow](http://nvie.com/posts/a-successful-git-branching-model/) way of managing project.
When working on maven project, there is few great plugins that helps to get
the work done. One of them is [maven-release-plugin](http://maven.apache.org/plugins/maven-release-plugin).

Inspired on this [gist](https://gist.github.com/1043970), I've come with
a cool way of doing things (let say we want to release a 0.1 version of an
artifact) :

# Prepare the pom.xml. 

It needs ``<scm>`` entries, ``<distributionManagement>`` entries
(to know where to deploy the release artifact) and few options for the
maven-release-plugin :

{% highlight xml %}
<project>

    <!-- […] -->
    <build>
        <plugins>
            <!-- […] -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-release-plugin</artifactId>
                <version>2.3.2</version>
                <configuration>
                    <tagNameFormat>v@{project.version}</tagNameFormat>
                    <pushChanges>false</pushChanges>
                    <localCheckout>true</localCheckout>
                </configuration>
            </plugin>
            <!-- […] -->
        </plugins>
    </build>
    <!-- […] -->

</project>
{% endhighlight %}

Few explanation here :

* ``tagNameFormat`` is here to change the default tag name (which is ``${project.artifactId}-${project.version}``) to a better one.
* ``pushChanges`` set to ``false`` tells  maven-release-plugin not to push
  changes (this will become useful)
* ``localCheckout`` set to ``true`` tells maven-release-plugin to clone from
  local repository (not distant). This is especially useful here because we
  didn't push anything (so not setting this option would result in a failure).

# The real stuff

First create a release branch from develop.

{% highlight bash %}
$ git checkout -b release/v0.1 develop
{% endhighlight %}

Then run the maven release stuff.

{% highlight bash %}
$ mvn release:prepare               # change the pom, commit and tag version, and
                                    # re-change pom (by incrementing SNAPSHOT version)
$ mvn release:perform               # get the tagged version, compile and deploy
{% endhighlight %}

And the real fun begins.

{% highlight bash %}
$ git checkout develop              # get back to the develop branch
$ git merge --no-ff release/v0.1    # merge the version back into develop
$ git checkout master               # go to the master branch
$ git merge --no-ff release/v0.1~1  # merge the version back into master but
                                    # the tagged version instead of the release/v0.1 HEAD
$ git branch -D release/v0.1        # Removing the release branch
$ git push --all && git push --tags # Finally push everything
{% endhighlight %}

The real magic here is the ``git merge --no-ff release/v0.1~1`` which will
merge into master the commit before the HEAD of the branch ``release/v0.1``.

The next step would be to create a helper script that automates this and
verify that the ``pom.xml`` has the right configuration options.
