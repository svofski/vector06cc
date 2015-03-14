# Как подключить vector06cc к цветному телевизору #

Начиная с версии [349](http://code.google.com/p/vector06cc/source/detail?r=349) vector06cc умеет формировать цветной композитный сигнал на выходе VGA-разъема платы DE1. Чтобы подключить плату к телевизору надо сделать переходник из штекера VGA на гнездо-RCA.
<pre>
1  R ---.<br>
\<br>
2  G -----*---> CVBS композит, центральный контакт<br>
/<br>
3  B ---'<br>
6,7,8 = GND -> земля, внешний контакт<br>
</pre>

Режим ТВ включается переключателями SW5 и SW4 (1 = TV). SW4 включает переворачивание фазы между полями, что необходимо для полноценного отображения всех цветов. Но, если картинка на вашем телевизоре выглядит странно, можно попробовать выключить SW4.

# How to connect vector06cc to a colour TV set #

Starting with revision [349](http://code.google.com/p/vector06cc/source/detail?r=349) vector06cc can be connected to a TV set through a composite cable. All you need to do is to make a connector that plugs into DE1 VGA out socket, join R,G,B wires together and connect them to a regular RCA video cable.
<pre>
1  R ---.<br>
\<br>
2  G -----*---> CVBS Composite, inner contact of RCA socket<br>
/<br>
3  B ---'<br>
6,7,8 = GND -> outer contact of RCA socket<br>
</pre>

TV Mode is switched on by turning up SW5 and SW4. SW4 is used for field phase alternation, if your picture is funny, try pulling SW4 down.