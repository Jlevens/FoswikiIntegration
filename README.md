# FoswikiIntegration
Analysis of Foswiki Dev &amp; Build tools; Extension issues on f.o &amp; in github


There is a lot still to do. I'm just capturing my work to date for safe keeping.

# To Do

1. Generic tool.pl (ToolsContrib concept) will run as www-data or self or www-data-plus?
  * Actually argument for www-data-plus so standard www-data cannot do some commands
  * Don't bother with internal changes now!
    * sudo -i -u www-data-plus tool.pl is ok for now (maybe create linux alias as syntactic sugar)
    * possible small change to exec self as www-data-plus (or complain) if running as wrong user
1. Need to get build tools working under windows
  * does that not mean Win32::Links
  * or at least well enough to work
  * or actually get it on CPAN!!
1. ToolsContrib concept where I can have a base tools
1. I can clone distro inside 'distro' and then 'mv' it into the right place
1. FCGI linked to high in pseudo-install. Actually, pseudo-install should always link as *low* as possible except for extension specfic named directories: ExtensionPlugin, ExtensionContrib and nothing else

1. Why do extension topics on the web *not* match those in git
  1. %$DESCRIPTION et al 'macros' processed during build
  1. Extra bits added during build - such as 'do not edit blah blad'
  * Former posisbly be removed if githooks could automate this
     * Remember that means topic will lose %$DESCRIPTION tags so hooks would need to be smart to know where to place them
  * Latter could become a VIEW_TEMPLATE

1. Remember the topic txt retrieved from f.o never has a trailing new-line bit git repo does
1. Use registerMETA for validation of topics passed?

1. What is in the git repo but not in the MANIFEST and impacts the user experience
  * i.e. a git based install will look different to a 'built' install
  * Can delete data/TestCases/WebPreferences.txt and never push back to git-hub
