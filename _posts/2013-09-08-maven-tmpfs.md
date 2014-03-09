---
layout: post
category: developement
tags: tag maven tmpfs ssd
bodyClass : gray
---
{% include setup %}

Je suis un utilisateur convaincu de [maven](), malgré ces défauts, le moto
__"Convention over configuration"__ me va vraiment bien. Que ce soit au boulot ou
à la maison, j'ai plus d'ordinateurs équipés de ssd (ou de mémoire flash) que de
disque traditionnel (mécanique ?). Pour augmenter un peu la durée de vie de
ces disques SSD, j'ai cherché à savoir comment _déporter_ le _build_ de maven
(qui, pour rappel, se passe dans le dossier ``target/``) hors du SSD ; ici ce
sera dans le dossier ``/tmp/`` qui est monté en mémoire (merci ``tmpfs``),
mais on peut imaginer déporter ça sur un autre disque, etc.. Après quelques
recherches j'ai trouvés quelques inspirations.

> __Limitations__
> 
> Dans la solution présentée ci-dessous les principales limitations sont
> les suivantes (que j'essaierais de diminuer au fil du temp ;P) :
> 
> 1. Il est nécessaire de modifier le pom.xml du projet ; cela ne s'appliquera
>     donc pas à tous les projets maven sans modification du pom.xml.
> 2. Cela ne fonctionne que sur une plateforme qui support les liens
>     symboliques (Linux, Mac OS X, et autre UNIX).
> 3. Cela ne fonctionne qu'avec Java 7 ou plus.
> 4. Si vous utilisez m2e, il va gentillement gueuler et c'est moche ; pour
>     résoudre le problème, il faut faire un tour vers [M2E plugin execution
>     not covered](http://wiki.eclipse.org/M2E_plugin_execution_not_covered).

Pour [maven](), le dossier ``target/`` vient de la propriété
``project.build.directory``. Dans la théorie, il suffirait de modifier (dans
``$HOME/.m2/settings.xml``) cette propriété et le tour serait jouer.
Malheuresement ce n'est pas possible, ``project.build.directory`` est une
propriété interne et n'est, à priori, pas modifiable.

Notre souhait est le suivant :

1. Le build doit se faire dans ``/tmp/m2/``, ce qui pour un projet se traduit
    par ``/tmp/m2/${groupId}:${artifactId}``.
2. Le dossier ``target/`` dans les sources est un lien symbolique vers le
    dossier dans ``/tmp/m2/``
3. On passe par un __profile__ qui n'est __pas actif__ par défaut (pour ne pas
    faire chier le monde) mais __activable via une propriété__ (maven nous permet
    de le faire et c'est cool ``^_^``). La propriété utilisée sera
    ``external.build.root``.

Le code ci-dessous est repris directement de mon inspiration[^inspiration]. Il
s'occupe de créer le dossier ``${groupId}:${artifactId}`` dans 
``external.build.root`` et de faire le lien dans le dossier courant.

{% highlight xml %}
<project>
    <!-- […] -->
    <profiles>
        <profile>
            <id>external-build-dir</id>
            <activation>
                <activeByDefault>false</activeByDefault>
                <property>
                    <name>external.build.root</name>
                </property>
            </activation>
            <build>
                <plugins>
                    <plugin>
                        <groupId>com.alexecollins.maven.plugin</groupId>
                        <artifactId>script-maven-plugin</artifactId>
                        <version>1.0.0</version>
                        <executions>
                            <execution>
                                <id>prep-work-tree</id>
                                <goals>
                                    <goal>execute</goal>
                                </goals>
                                <phase>initialize</phase>
                                <configuration>
                                    <script>
                                        import java.nio.file.*
                                        def dir =
                                        "${external.build.root}/${project.groupId}:${project.artifactId}"
                                        println "using Maven dir ${dir}"
                                        def dirPath = Paths.get(dir)
                                        if (!Files.exists(dirPath)) {
                                        Files.createDirectories(dirPath)
                                        }
                                        def target = Paths.get("${project.build.directory}")
                                        if (!Files.exists(target)) {
                                        Files.createSymbolicLink(target, dirPath)
                                        }</script>
                                </configuration>
                            </execution>
                            <execution>
                                <id>drop-symlink</id>
                                <goals>
                                    <goal>execute</goal>
                                </goals>
                                <phase>clean</phase>
                                <configuration>
                                    <script>
                                        import java.nio.file.*
                                        def target = Paths.get("${project.build.directory}")
                                        if (Files.isSymbolicLink(target)) {
                                        Files.delete(target)
                                        }
                                    </script>
                                </configuration>
                            </execution>
                        </executions>
                        <dependencies>
                            <dependency>
                                <groupId>org.codehaus.groovy</groupId>
                                <artifactId>groovy</artifactId>
                                <version>1.8.6</version>
                            </dependency>
                        </dependencies>
                        <configuration>
                            <language>groovy</language>
                        </configuration>
                    </plugin>
                </plugins>
            </build>
        </profile>
    </profiles>
    <!-- […] -->
</project>
{% endhighlight %}

Ainsi, il suffit ensuite d'avoir quelques choses du genre dans son
``$HOME/.m2/settings.xml`` pour que les builds qui ont ce profil se _build_
dans ``/tmp/m2/``. On peut aussi ne rien avoir dans ``$HOME/.m2/settings.xml``
et utilise ``-Dexternal.build.root=/tmp/m2/`` avec la commande ``mvn``.

{% highlight xml %}
<settings>
    <!-- […] -->
    <profiles>
        <profile>
            <id>build-in-ramfs</id>
            <properties>
                <external.build.root>/tmp/m2/</external.build.root>
            </properties>
        </profile>
    </profiles>
    <activeProfiles>
        <activeProfile>build-in-ramfs</activeProfile>
    </activeProfiles>
    <!-- […] -->
</settings>
{% endhighlight %}

[^inspiration]: [Putting Maven build directories out-of-tree](http://elehack.net/writings/programming/maven-target-in-tmpfs) par [Michal Ekstrand](http://elehack.net/)
[maven]: http://maven.apache.org/
