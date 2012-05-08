---
title: Notes on MySQL
layout: page
body_class: green
group: navigation
tags: [linux, mysql]
lang: fr
---
{% include setup %}

## Compatibilités

Si par un malheureux hasard vous avez des problèmes de `BTREE` en essayant de
restaurer un dump MySQL, il faut _juste_ réaliser le dump avec les options de 
compatibilités.. 

    $ mysqldump -u ${user} -p ${database} --compatible=mysql40
