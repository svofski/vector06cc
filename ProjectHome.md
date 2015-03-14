This project is a complete open source replica  of [Vector-06C](http://en.wikipedia.org/wiki/Vector-06C) (Russian: Вектор-06Ц), a retro, Soviet-era home computer, in a [FPGA](http://en.wikipedia.org/wiki/FPGA). If you're new to this, [fpga4fun](http://fpga4fun.com) is a good place to start learning.

[Altera DE1](http://www.altera.com/products/devkits/altera/kit-cyc2-2C20N.html) development board with Cyclone II FPGA is the primary development platform.

The project uses a mixture of Verilog and VHDL code. All original code is written in Verilog, while some of the modules, e.g. [T80 CPU](http://opencores.org/?do=project&who=t80) and [82C55](http://home.freeuk.com/fpgaarcade/library.htm) PIO controller are written in VHDL.

This version of T80 is the most accurate implementation of 8080 to date. The complete set of [8080 Exerciser](http://www.sunhillow.eu/8080exerciser/) test results matches that of the real CPU.

Make sure to browse the Wiki, GettingStarted is a nice place to start. Also check out the [videos](http://www.youtube.com/view_play_list?p=8750FB243935EDE2) of work in progress. Returning users please check [Revision\_History](Revision_History.md) page for news.

![http://vector06cc.googlecode.com/svn/trunk/doc/putupchik.jpg](http://vector06cc.googlecode.com/svn/trunk/doc/putupchik.jpg)

Этот проект полностью воссоздает цветной компьютер [Вектор-06Ц](http://ru.wikipedia.org/wiki/%D0%92%D0%B5%D0%BA%D1%82%D0%BE%D1%80-06%D1%86) без зеленых конденсаторов. Весь компьютер, включая процессор и дисковод, помещается в одной микросхеме ПЛИС, а его структура и поведение описаны на языках Verilog и VHDL. Если вы не знаете, что это такое, но хотите узнать, сходите на [fpga4fun](http://fpga4fun.com).

Проект разрабатывается на плате [Altera DE1](http://www.altera.com/products/devkits/altera/kit-cyc2-2C20N.html). Часть кода заимствована из других открытых проектов. В частности, использованы ядра [T80 CPU](http://opencores.org/?do=project&who=t80), [82C55](http://home.freeuk.com/fpgaarcade/library.htm).

Используемая в этом проекте версия процессора T80 является самой точной на сегодняшний день реализацией процессора КР580ВМ80А. 100% результатов теста  [8080 Exerciser](http://www.sunhillow.eu/8080exerciser/)  совпадают с полученными на настоящем процессоре данными.

Начните с прочтения руководства GettingStarted на Вики. Оно написано на двух языках и содержит ссылки на другие документы. Можно также посмотреть на [ютубы](http://www.youtube.com/view_play_list?p=8750FB243935EDE2) снятые на разных стадиях создания компьютера. На странице [Revision\_History](Revision_History.md) находится журнал версий.