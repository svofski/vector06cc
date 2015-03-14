## Intro ##
This is a hardware project, which means that you can't e.g. just download, compile and run it on your PC. In order to be useful, it requires a compatible development board with an appropriate FPGA. As of time when this document is written, there's only one such board and it's called Altera Cyclone II Starter Kit, otherwise known as DE1 starter kit.

The original Vector-06C computer uses a KR580 CPU, which is a clone of Intel 8080. This work, however, is based on a T80 CPU core by Daniel Wallner. T80 was designed to be an accurate model of Z80, not 8080 and although it has a 8080 mode, its not perfectly accurate. This project contains changes made in order to make T80 core in Mode2 cycle-accurate with i8080. Also, original T80 does not implement STACK signal. I needed it because Vector-06C uses STACK for its unique RAMdisk operation, so I added STACK to T80 too.

> Это хардверный проект. Для того чтобы увидеть что это такое, необходима специальная плата с соответствующей FPGA и периферией. На момент написания этого документа, такая плата только одна и называется она Altera Cyclone II Starter Kit, или Altera DE1.

> Настоящий Вектор-06Ц был построен на процессоре КР580. Этот проект использует softcore процессор T80 Даниеля Валнера. T80 разрабатывался прежде всего как Z80 и, хотя у него был предусмотрен режим 8080, мне пришлось внести некоторое количество изменений в оригинальный код. В частности, были исправлены времена исполнения многих инструкций, к слову состояния был добавлен сигнал STACK, добавлены "недокументированные" инструкции, "испорчена" инструкция DAA, исправлены сигналы HOLD/HLDA.

## Requirements ##
Basically you only need one thing: [Cyclone II Starter Kit or Altera DE1](http://www.altera.com/products/devkits/altera/kit-cyc2-2C20N.html). If you don't have one and have a different board, you're **intensely** welcome to port this project to that board. It is of course a good idea to keep the portage stuff clean and separate, so that different hardware adaptations would use a single source base.

> Кроме отладочной платы, [Cyclone II Starter Kit or Altera DE1](http://www.altera.com/products/devkits/altera/kit-cyc2-2C20N.html), ничего больше не требуется. Если у вас есть другая плата и опыт, добро пожаловать, спортируйте этот проект на свою плату и расскажите мне.

## Making it work ##
Provided you have DE1 board and it's connected to your host PC and Quartus II is installed, you can:
  * Download source code and compile it
  * Download binary release and upload it directly
In any occasion you must be absolutely sure that you have DE1 board and nothing else. It WILL NOT work on anything else and it WILL DAMAGE your non-DE1 board. I don't take any responsibility for damaged hardware.

Usually it's a preferred choice to download and compile the source from SVN, because snapshot releases are not prepared regularly and you could miss some recent fixes. Check with [Revision\_History](Revision_History.md), which is kept up to date with SVN commits.

> Если у вас есть DE1 и все настроено, можно либо скачать сорцы и откомпилировать их, для этого нужен Quartus II Web Edition, либо же можно скачать bitstream (binary) файл и просто залить его в плату. Не надо пытаться заливать этот файл в другую плату, даже если там стоит такая же FPGA -- все сгорит, из микросхем выйдет весь волшебный дым и они перестанут работать.

> Лучше выкачивать исходники из репозитория SVN, потому что снепшоты и билды, строятся не регулярно, а очень изредка и можно не застать самые свежие исправления. Заглядывайте в [Revision\_History](Revision_History.md) на предмет последних изменений, эта страничка поддерживается в актуальном состоянии.

## After the firmware is uploaded ##
Provided that your monitor supports 720x576@50Hz mode, which most modern LCD monitors should support, upon startup you will see a blue screen with yellow grid, the top line saying "ВЕКТОР-06Ц" and there would be a tape icon. If you see this picture, everything is perfect! If you don't, start fixing the code and submitting patches.

Now that you have the hardware, you want to upload software. You can search for Vector-06C software in .rom files, or you can download a ramdisk image with a couple of programs from my homepage on http://sensi.org/~svo/vector06c

> Если монитор поддерживает режим 720x576@60Hz, все должно быть хорошо. Сразу после загрузки битстрим файла должна появиться синяя картинка с желтой сеткой загрузчика. Если ее видно, значит уже все неплохо. Если не видно, очень жаль. Смотрим ниже про переключатели.

### DE1 Switches ###
See README.txt, or comments in vector06cc.v for details, but long story short: SW8 and SW9 must be in the "1" or "Up" position. The rest are unimportant. Also, KEY0 is Reset with boot rom (power-on reset) and KEY3 is romless reset (БЛК+СБР), same as F12 key starts the loaded software.

#### Full switches breakdown: ####
|SW1:SW0|red LED[7:0] display selector|00: Data In<br>01: Data Out<br>11: registered Data Out<br>
<tr><td>SW3:SW2</td><td>green LED group display selector</td><td>00: registered CPU status word<br>01: keyboard status/testpins<br>10: RAM disk test pins<br>11: WR_n, io_stack, SRAM_ADDR[17:15] (RAM disk page)</td></tr>
<tr><td>SW4</td><td>1 = PAL field phase alternate (should be on for normal tv's)</td><td>See <a href='TV_Howto.md'>TV_Howto</a> </td></tr>
<tr><td>SW5</td><td>1 = CVBS composite output on VGA R,G,B pins</td><td>See <a href='TV_Howto.md'>TV_Howto</a></td></tr>
<tr><td>SW6</td><td>1 = disable tape in</td><td>  </td></tr>
<tr><td>SW7</td><td>manual bus hold</td><td>recommended for SRAM/JTAG exchange operations</td></tr>
<tr><td>SW9:SW8</td><td>Clock modes</td><td>These must be both "1" for normal operation:<br>00: single-clock, tap clock by KEY<a href='1.md'>1</a><br>01: warp mode: 6 MHz, no waitstates<br>10: slow clock, code is executed at eyeballable speed<br>11: normal Vector-06C speed, full compatibility mode</td></tr></tbody></table>


<blockquote>Вкратце: SW8 и SW9 должны быть в верхнем положении "1", остальные лучше перевести в положение "0". Кроме того, есть кнопки: KEY0 выполняет полный сброс, кнопка KEY3 -- загрузку, то же что клавиша F12 на клавиатуре или БЛК+СБР на настоящем Векторе. Клавиша F11 == БЛК+ВВОД.</blockquote>

<h2>Using software</h2>
There are several methods of running software. Here they are in order of ease of use. You will need <b>Cyclone II Starter Kit Control Panel</b> program supplied with your DE1 board in order to transfer data to the board's SRAM.<br>
<br>
<blockquote>Есть несколько способов запускать программы. Они приводятся в порядке убывания простоты использования. К плате DE1 прилагается интересный пример под названием Cyclone II Starter Kit Control Panel, он позволяет общаться с памятью установленной на плате. Это очень полезная программа.</blockquote>

<h3>Floppy disk images</h3>
vector06cc can load standard Vector-06C floppy disk images in .fdd format. You need to create a folder called "VECTOR06" in the root of a FAT16-formatted SD/MMC card and put  .fdd files in that folder. Different images can be selected via the OSD menu, see <a href='HOWTO_Floppy.md'>HOWTO_Floppy</a>. If a floppy you need is not bootable you can still boot MicroDOS from the RAM disk, or boot from another floppy image and change disks after that.<br>
<br>
<blockquote>vector06cc может загружать стандартные эмуляторные образы в формате .fdd. Создайте каталог под названием "VECTOR06" в корне отформатированной в FAT16 SD или MMC карточки. В этот каталог можно положить образы дискеток. Если образ нужной дискеты не загрузочный, можно загрузить МикроДОС с квазидиска, или загрузиться с другой дискеты, а затем сменить диск. Смотри также <a href='HOWTO_Floppy.md'>HOWTO_Floppy</a>.</blockquote>

<h3>RAMdisk image</h3>
Use the control panel to upload ramdisk.img (or .edd or whatever, the size should be 256K) starting with address <b>8000</b> (this is hex). Make sure that you select SRAM tab, select sequential upload, check "File size" checkbox and chose a file. After you uploaded the image, press RESET (KEY0) again, the screen must fill with full yellow boxes, address "EB" should be held on the hex display and LED9 must be blinking steady. Now you can press F12 on the PS/2 keyboard to boot into MicroDOS. Change disk to C:, "D" is for "Directory". See <a href='MicroDOS_manual.md'>MicroDOS_manual</a> for more on MicroDOS.<br>
<br>
<blockquote>Образ квазидиска, см. ссылки, нужно закачивать с адреса 0x8000. Выберите закладку <b>SRAM</b>, Sequential Write, пометьте галочку <b>File Size</b>, выберите файл ramdisk.img и он закачается в память. После этого нужно сбросить Вектор кнопкой KEY0, или клавишей F11 на клавиатуре. Если все прошло нормально, после сброса должна появиться иконка квазидиска и будет загружена <a href='MicroDOS_manual.md'>МикроДОС</a>. Нажимайте F12 и появится приглашение ОС. Квазидиск является диском C:  Команда для просмотра каталога - D.</blockquote>

<h3>ROM files</h3>
After Vector-06C is loaded, if there's nothing in RAMdisk, it expects things to be loaded from tape. However, today in late 2000's we can bypass the tape and load stuff directly into RAM. For that, open CII Control Panel, open USB port, select SRAM tab, Sequential Write, check "File Length" and the start address should be <b>80</b> (0x100 in bytes == 0x80 in words). After file is written to memory display will not change, but the data will be in RAM. Press F12 on keyboard and there you go.<br>
<br>
<blockquote>Если квазидиск пуст, Вектор захочет грузиться с кассеты. Но можно загрузить образ программы прямо в память способом аналогичным предыдущему. Разница заключается в том, что .rom файл нужно загружать с адреса 0x80 и после загрузки нажимать сразу F12.</blockquote>

<h3>Load from Tape</h3>
Audio input works and you can load from .wav file, .mp3 file (96kbps seems to be working best), iPod, tape player, whatever --- provided you have any wav's or tapes. This process will not differ from the original Vector-06C or any other computer, after image is loaded, RUS/LAT LED will blink steady (LED9) and F12 on the keyboard will start the program. See <a href='HOWTO_rom2wav.md'>ROM-&gt;WAV howto</a>

<blockquote>Можно загружать программы из wav- или mp3- файлов, как было принято во времена моноклей и высоких цилиндров. В этом проекте реализован адаптивный уровень чтения, поэтому никакой настройки плеера не понадобится. См. также <a href='HOWTO_rom2wav.md'>ROM-&gt;WAV howto (ru)</a>.</blockquote>

<h1>Other pages of interest</h1>
<ul><li><a href='license.md'>Licensing information (en)</a>
</li><li><a href='HOWTO_Floppy.md'>Floppy howto | Как пользоваться дисководом</a>
</li><li><a href='HOWTO_rom2wav.md'>ROM-&gt;WAV howto (ru) | Как из .ROM сделать .WAV</a>
</li><li><a href='Technical_Description.md'>Technical Description of Vector-06C by Alexander Timoshenko (ru) | Техническое описание Вектора-06Ц</a>
</li><li><a href='MicroDOS_manual.md'>MicroDOS manual (ru) | Руководство пользователя МикроДОС</a>
</li><li><a href='ramdisk.md'>RAM disk documentation, various sources (ru) | Описание квазидиска</a>
</li><li><a href='ImplementationNotes.md'>FPGA Implementation Notes</a>
</li><li><a href='JTAG_Implementation.md'>DE1 USB API compatible JTAG implementation</a>
</li><li><a href='SoundCodec.md'>Audio Codec interface</a>
</li><li><a href='SVK1_Floppy.md'>Секреты Вектора и Кристы</a> - глава с описанием контроллера дисковода<br>
</li><li><a href='VectorSecrets_by_Lebedev.md'>Секреты Вектора</a> от А.З. Лебедева<br>
</li><li><a href='Oddities.md'>Oddities and observations</a>