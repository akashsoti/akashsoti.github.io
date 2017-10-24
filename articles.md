---
layout: default
title: Your New Jekyll Site
---
<h1 class="pageTitle">Prototypes</h1>
<div class="pageTitle-helper"><p>I love making prototypes and my favourite tools are Framer JS, Principle and Xcode</p></div>
<div id="articles">
  <h1>Articles</h1>
  <ul class="posts noList">
    {% for post in site.posts %}
      <li>
      	<span class="date">{{ post.date | date_to_string }}</span>
      	<h3><a href="{{ post.url }}">{{ post.title }}</a></h3>
      	<p class="description">{% if post.description %}{{ post.description  | strip_html | strip_newlines | truncate: 120 }}{% else %}{{ post.content | strip_html | strip_newlines | truncate: 120 }}{% endif %}</p>
      </li>
    {% endfor %}
  </ul>
</div>