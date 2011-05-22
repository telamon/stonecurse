Stone Curse
-----------

This class takes an URL as input and inlines all references to
javascripts, stylesheets and images into the html. 

usage:

> File.open('goog.html', 'w'){ |f|
>   f.write Stonecurse.new("http://google.com").petrify 
> }

I came up with this idea when I was about to fall asleep but
I have to confess that I have no idea what to use this class for.
Maybe you can figure it out.