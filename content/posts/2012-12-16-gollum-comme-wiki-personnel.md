---
title: "Gollum Comme Wiki Personnel"
date: "2012-12-16"
categories:
    - me
tags:
    - wiki
    - gollum
    - github
    - personnel
lang: fr
bodyClass : gray
aliases:
    - /2012/12/gollum-comme-wiki-personnel/
---

Il y a environ 4 mois j'ai eu un accident de vélo ; un traumatisme crânien, des brulures sur la face, quelques points de sutures, un doigt cassé et une hernie discale m'ont cloué (et me clou encore) plus que d'habitude sur ma chaise de bureau. Le bon côté des choses, c'est que cela m'a permit de me poser et de réfléchir une bonne façon d'être efficace et organiser, au travail et à la maison :-).

Une des principales _action_ que j'ai pris est d'utiliser un wiki local et synchronisé sur _tout_ mes PCs. Le _format_ wiki est assez adapté à une prise de note et à la création de contenu plus complet (comme des [articles][] ou de la documentation pour des projets en cours). Les conditions étaient les suivantes :

* Facilité de mise en place.
* Pas de base de données.
* _Merging_ facile ([git][] _rules my world_).
* [Markdown][] comme syntaxe, car utilisé à peu près partout (blogs, articles, READMEs, documentations).
* Éditable à partir d'une interface web ou de mon éditeur favoris.

L'outil qui remplit presque toutes ces conditions s'appelle [gollum][]. C'est un moteur wiki, écris en ruby, qui se base sur un repository [git][]. Il est développer par l'équipe de [Github][] et c'est celui qui est utilisé par les pages wiki là-bas. Il permet d'utiliser à peu près n'importe quel syntaxe (dont [github-markdown][] qui est assez proche de celle de [pandoc][]). Par ailleurs, comme il se base sur [git][], les points _"pas de base de données"_, _"merging facile"_ et _"éditable également à partir de mon éditeur favoris"_ sont toutes remplies.

Avec [Gollum][] vous avez un wiki markdown décentralisé, éditable via une interface web ou via votre éditeur favoris.

## Mise en place

La mise en place est relativement simple ; après tout dépend du besoin que vous avez. L'installation se fait par [RubyGem][] ou en clonant le repository.

{{< highlight bash >}}
# Installation de gollum et du format markdown de github
$ gem install gollum gitub-markdown
{{< /highlight >}}

Si vous n'utilisez pas [rbenv][] ou [rvm][] il est probable qu'il faille lancer la commande en root ou utiliser sudo.

Ensuite, il suffit de lancer [Gollum] dans un dossier qui est un repository git ; le tour est joué

{{< highlight bash >}}
# J'ulitise ~/desktop/wiki pour mon wiki
$ cd ~/desktop/wiki && gollum
{{< /highlight >}}

L'idée finale est d'automatiser deux choses :

1. Le démarrage de gollum 
2. La synchronisation du repository avec les différents autres _remotes_

Suivant le système d'exploitation et/ou la distribution utilisées, il y a énormément de possibilité d'effectuer cette automatisation. Dans mon cas, j'ai une [Debian][] assez light, avec surtout plein de scripts. Je démarre donc [Gollum][] au démarrage de ma session grâce à une script qui est lancé dans la foulée du gestionnaire de fenêtre. La synchronisation se fait grâce à une tâche planifiée _cron_ qui est "distribué" sur chacune de mes machines.

_C'est tout pour le moment_ ;-).

[debian]: http://debian.org
[RubyGem]: rubygems.org
[rbenv]: https://github.com/sstephenson/rbenv
[rvm]: https://rvm.io/
[gollum]: https://github.com/github/gollum
[articles]: http://shortbrain.org
[git]: http://git-scm.com
[github]: http://github.com
[Markdown]: http://daringfireball.net/projects/markdown/
[github-markdown]: https://github.com/github/github-flavored-markdown
[pandoc]: http://johnmacfarlane.net/pandoc
