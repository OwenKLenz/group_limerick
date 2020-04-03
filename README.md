# Group Limerick

### Preface
I built this game as an optional side project at the end of [Launch School](https://launchschool.com/)'s RB175 course on designing Networked Applications.
This is my first attempt at crafting an original web application. The back end is built in Ruby using the Sinatra framework and the front end is built with with my underdeveloped skills in HTML and CSS with a little jQuery thrown in for good measure to facilitate auto-refreshing and some simple hide/show animations.

Note: This app was designed while sheltering in place during the COVID-19 pandemic and my hope is that the game might be a fun diversion for family and friends during these difficult times.

### What is a limerick?
As defined on [literarydevices.net](http://literarydevices.net/limerick):
*Limerick is a comic verse, containing five anapestic (unstressed/unstressed/stressed) lines, in which the first, second, and fifth lines are longer, rhyme together, and follow three metrical feet. The third and fourth lines rhyme together, are shorter, and follow two metrical feet. However, sometimes it may vary, and amphibrachic (unstressed/stressed/unstressed) form can replace anapestic. In fact, it is a bawdy, humorous, or nonsensical verse written in the form of five anapests, with an aabba rhyme scheme. Since it has a special structure and format, it is called fixed or closed form of poetry.*

- The bawdier and more uncouth, the better.

### What is Group Limerick?
A delightful game that can be played with 2-5 people. Each person concocts the first line of a limerick and then passes the limerick to the person next to them. This process repeats until the limerick is finished, at which point the results are read aloud and hearty laughs are shared.

### Implementing Group Limerick as a web app
The big challenge with Group Limerick was working out how to provide a multiplayer experience that could be enjoyed on the internet by multiple clients. Further complicating matters was the stateless nature of HTTP, which inherently makes it difficult to do things like keep track of each player's contributions to the game and ensuring that each player is served up the appropriate data at each phase of the game.

The next phase in my learning at Launch School will introduce me to the world of databases, a seemingly excellent solution to the problem of tracking and persisting game state for several players, but for now, I had to devise another solution to allow me to create a shared game state that would persist for the whole game and be accessible by all players.
****