package com.classes{
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.geom.Point;
	import com.classes.Player;
	
	import com.senocular.KeyObject;
	
	import com.greensock.TweenLite;
	import com.greensock.easing.*;
	
	public class Engine extends MovieClip{
		private var gameDifficulty:int;
		private var key:KeyObject;
		private var player:Player;
		private var scrollX:Number = 0;
		private var scrollY:Number = 0;
		private var speedX:Number= 0;
		private var speedY:Number = 0;
		private var maxspeedXConstant:Number = 7;
		private var maxspeedYConstant:Number = 10;
		private var gravityConstant:Number = 2;
		private var speedXConstant:Number = 8;
		private var speedYConstant:Number = 8;
		private var jumpConstant:Number = -20;
		private var friction:Number = 0.70;
		private var playerStartPositionX = 400;
		private var playerStartPositionY = 400;
		private var playerWalking:Boolean = false; //Игрок двигается влево или вправо
		private var playerJumping:Boolean = false; //Игрок прыгает
		private var playerLanding:int = 0; //Считаем, как долго игрок приземляется
		private var playerAimsUp:Boolean = false; //Игрок целится вверх (45 градусов в сторону поворота)
		private var playerAimsDown:Boolean = false; //Игрок целится вниз(45 градусов в сторону поворота)
		private var leftBumping:Boolean = false; //Игрок упёрся в левую стенку
		private var rightBumping:Boolean = false; //Игрок упёрся в правую стенку
		private var upBumping:Boolean = false; //Игрок упёрся в потолок
		private var downBumping:Boolean = false; //Игрок упёрся в пол (например, когда стоит на земле)
		private var playerCollisionPoints:Array = new Array(new Point(-15, 0), new Point(15, 0), new Point(0, -68), new Point(0, 68)); //Точки проверки соприкосновения игрока и уровня
		private var shots:Array = new Array(); //Массив всех выстрелов на экране
		private var reloading:Boolean = false; //Перезаряжается ли игрок в данный момент
		private var shotDelay:int = 20; //задержка между выстрелами
		private var shotAnimationDelay:int = 21;
		private var reloadingBetweenShots:Boolean = false; //Флаг задержки между выстрелами
		private var ammo:Array = new Array(); //массив патронов (обойма)
		private var reloadingTimer:int = 20; //Переменная, имитирующая таймер перезарядки (1 патрон) (кадров)
		private var bulletSpeed:int = 30; //Скорость пули
		private var enemiesArray:Array = new Array(); //Массив с врагами
		private var playerHitTimer = 0; //Задержка между попаданиями по игроку
		private var sounds:Array; //Массив звуков (берётся из Base)
		private var second:int = 1; //Счётчик кадров для таймера
		private var timeToDeath:int; //Общее время до смерти
		
		public function Engine(){ //Конструктор
			trace('start');
			if(stage) init(null); //Из-за рассинхронизации добавления объекта на сцену на нужно проверять, добавлен ли этот объект уже на сцену
			else addEventListener(Event.ADDED_TO_STAGE, init); //если да, то просто вызываем функцию init(), в противном случае создаём слушатель событий для
																//события "добавление объекта на сцену", и как только это произойдёт, всё равно запускаем функцию init()
		}
		
		private function init(e:Event):void{
			removeEventListener(Event.ADDED_TO_STAGE, init); //удаляем слушатель событий
			gameDifficulty = MovieClip(parent).getDifficulty();
			sounds = MovieClip(parent).getSounds();
			key = new KeyObject(stage);
			player = new Player(3 - gameDifficulty); //Создаём игрока
			addChild(player); //И добавляем его на экран
			player.x = playerStartPositionX; //Перемещаем его на начальную позицию
			player.y = playerStartPositionY;
			for (var i:int = 0; i < 6; i++){
				reloadAmmo(); //Заряжаем "обойму"
			}
			
			timeToDeath = 120 - 15*MovieClip(parent).getDifficulty(); //Ставим время до смерти в зависимости от сложности игры (секунд)
			timer.text = String(timeToDeath); //Пишем оставшееся время
			
			lives.text = String(player.getHealth()); //Пишем кол-во жизней
			
			stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler); //Добавляем слушатель событий для входа в кадр (у нас: 30 кадров в секунду)
			MovieClip(parent).setChildIndex(MovieClip(parent).soundControl, MovieClip(parent).soundControl.parent.numChildren-1); //Помещаем значок звука на самый верх
						
			setEnemies(); //Расставляем врагов
			
			hitScreen.mouseEnabled = false; //Отключаем клики по красному экрану (кровь при попадании по игроку). Нужно для кнопки включения/выключения звука
			winScreen.mouseEnabled = false; //Отключаем клики по зелёному экрану (при/после победы). Нужно для кнопки включения/выключения звука и тд
		}
		
		private function setEnemies():void{ //Создаём врагов следующим образом: в объекте levels класса levelX (пока только level1) есть слой enemies.
											//В этом я разместила мувиклип enemyPositions, наполненный красными кружочками 
											//(объектами game_folder/levels_folder/level 1/pos).
			levels.enemyPositions.alpha = 0; //Для начала я скрываю этот мувиклип
			for (var i:int = 0; i < levels.enemyPositions.numChildren; i++){ //И для каждого объекта pos в enemyPositions (т.е. для каждого врага)
				enemiesArray[i] = new Enemy1(1 + gameDifficulty); 	//Создаю новый объект класса Enemy1 (в будующем их может быть и больше). Как входной параметр
																	//для конструктора Enemy1 я передаю кол-во жизни у монстра, зависящее от сложности игры. Минимальное
																	//количество жизней - одна, т.е. враг будет умирать от первого попадания
				levels.addChild(enemiesArray[i]); //Отображаю врага на экране
				enemiesArray[i].x = levels.enemyPositions.getChildAt(i).x; 	//и даю ему позицию Х/У тех самых красных кружочков pos.
				enemiesArray[i].y = levels.enemyPositions.getChildAt(i).y; 	//Иными словами я могу просто расставлять врагов при создании уровня, а они, в свою очередь,
																			//будут автоматически сохраняться в массиве enemiesArray[] для дальнейшей обработки
			}
		}
				
		private function enterFrameHandler(e:Event):void{ //Функция стрельбы
		
			//Отсчитываем время до смерти
			second--;
			if (second < 1){
				second = int(stage.frameRate); //Считываем кол-во кадров в секунду, установленное для игры
				timer.text = String(timeToDeath--);
				if (timer.text == '0'){
					sounds[5].play(); //Проигрываем звук смерти
					var gameObject = this; //Если функция возвратила нам true, значит игрок умер
					this.setChildIndex(hitScreen, hitScreen.parent.numChildren-1); //Перемещаем экран попадания по игроку (кровь) на самый верх
					stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler); //Убиваем слушатель событий по входу в кадр
					player.gotoAndPlay('die'); //Показываем анимацию смерти
					TweenLite.delayedCall(3, function(){TweenLite.to(hitScreen, 2, {alpha: 1});}); //и отображаем "смерть" (заливаем экран красным в течении двух секунд с задержкой в три секунды)
					TweenLite.delayedCall(5, function(){  //С задержкой в 5 секунд после непосредственной "смерти" игрока,
						MovieClip(parent).gotoAndPlay('game_over'); //прыгаем в кадр "game_over"
						MovieClip(parent).removeChild(gameObject); //а также убираем объект игры с экрана
					});
					return; //Выходим из функции
				}
			}
			
			if (key.isDown(key.SPACE) && playerLanding == 0  && !playerJumping){ //Если мы не приземляемся и не прыгаем (не в воздухе)
				var bulletSpeedY:int = 0; //Скорость пули по оси У
				var bulletOffsetX:int = 0; //Смещение точки создания пули по оси Х для разных направлений выстрела
				var bulletOffsetY:int = 0; //Смещение точки создания пули по оси У для разных направлений выстрела
				
				if (!reloading && !reloadingBetweenShots){ //Если не перезаряжаемся и нет задержки между выстрелами, можно стрелять
					if (playerAimsUp){
						player.gotoAndPlay('shot_up'); //Изображаем стрельбу
						bulletOffsetX = 15;
						bulletOffsetY = -53;
					}
					else if (playerAimsDown){
						player.gotoAndPlay('shot_down');
						bulletOffsetX = 20;
						bulletOffsetY = -7;
					}
					else {
						player.gotoAndPlay('shot');
						bulletOffsetX = 40;
						bulletOffsetY = -35;
					}
					shotAnimationDelay = 11; //Считаем, как долго будет отображаться стрельба (кадров)
					
					var negaviteBulletDirection:int = -1; //Если игрок повёрнут влево
					if (player.scaleX > 0){ //Даём пуле направление полёта (влево/вправо в зависимости от поворота игрока)
						negaviteBulletDirection = 1;
					}
					
					if (playerAimsDown) bulletSpeedY = bulletSpeed * negaviteBulletDirection * player.scaleX;
					else if (playerAimsUp) bulletSpeedY = bulletSpeed * -negaviteBulletDirection * player.scaleX;
					shots.push(new Shot(bulletSpeed * negaviteBulletDirection, bulletSpeedY)); //Добавляем пулю в массив пуль
					levels.addChild(shots[shots.length - 1]); //Отображаем пулю на экране
					levels.setChildIndex(shots[shots.length - 1], numChildren+1);
					speedX -= negaviteBulletDirection*3; //Создаём отдачу, снижая скорость перемещения игрока по оси Х (пренебрегаем осью У)
					shots[shots.length - 1].x = -levels.x + player.x + bulletOffsetX*negaviteBulletDirection ; //Помещаем пулю на нужные координаты х/у
					shots[shots.length - 1].y = -levels.y + player.y + bulletOffsetY;
					sounds[0].play();
					trace('shot!');
					magazine.removeChild(ammo[ammo.length-1]); //Убираем одну пулю из магазина
					ammo.splice(ammo.length-1, 1); //Удаляем её из массива "обоймы"
					if (ammo.length < 1){ //Если патронов в массиве обоймы не осталось, запускаем перезарядку
						trace('reloading ammo!!!!');
						reloading = true; //И запрещаем стрелять
					}
					reloadingBetweenShots = true; //После выстрела включаем задержку до следующего выстрела
				}
			}
			
			if (reloadingBetweenShots){ //Считаем задержку между выстрелами
				shotDelay--;
				if (shotDelay == 0){
					reloadingBetweenShots = false;
					shotDelay = 10;
				}
			}
			
			if (shotAnimationDelay > 0){ //Если игрок выстрельнул, то рисуем анимацию выстрела до конца (10 кадров + 1, чтоб не было прерываний)
				shotAnimationDelay--; //Считаем длительность анимации
				if (shotAnimationDelay == 0){ //Теперь немного криво. Нам надо всего лишь 1 раз присвоить переменной playerWalking значение false, чтобы, если игрок
					shotAnimationDelay = -1; //держит кнопки бега, снова начать отрисоввывать анимацию передвижений. Для этого даём переменной shotAnimationDelay значение -1
				}
			}
			if (shotAnimationDelay == -1){ 	//и таким образом попадаем в следующий блок,
				playerWalking = false;		//в котором, собственно, и меняем значение переменной playerWalking,
				shotAnimationDelay = 0;		//а после даём переменной shotAnimationDelay значение 0 и больше не попадаем в этот блок до следующего выстрела
			}
			
			if (reloading){ //Перезаряжаем оружие
				if (reloadingTimer > 0){
					reloadingTimer--;
				}
				else{
					reloadingTimer = 10;
					reloadAmmo();
					if(ammo.length == 6){
						reloading = false;
					}
				}
			}
			
			moveBullets();
			
			if (key.isDown(key.LEFT) && (playerLanding == 0  || playerJumping)){
				movePlayer('left');
			}
			if (key.isDown(key.RIGHT) && (playerLanding == 0 || playerJumping)){
				movePlayer('right');
			}
			
			if (key.isDown(key.DOWN)){
				playerAimsDown = true;
			}
			else{
				playerAimsDown = false;
			}
			
			if (key.isDown(key.UP)){
				playerAimsUp = true;
			}
			else{
				playerAimsUp = false;
			}
			
			if (!key.isDown(key.LEFT) && !key.isDown(key.RIGHT) && !playerJumping && playerLanding == 0 && shotAnimationDelay == 0){ //Если игрок не идёт
				playerWalking = false;
				player.gotoAndPlay('stand');
			}
			else if (!key.isDown(key.LEFT) && !key.isDown(key.RIGHT) && !playerJumping && playerLanding == 0){ //Стреляет и не идёт
				player.legs.gotoAndPlay('stand');
			}
			else if (key.isDown(key.LEFT) && key.isDown(key.RIGHT) && !playerJumping && playerLanding == 0 && shotAnimationDelay == 0){ //При нажатии обеих клавишь влево и вправо
				player.gotoAndPlay('stand');
				playerWalking = false;
			}
			
			if(levels.hitobjects.hitTestPoint(player.x + playerCollisionPoints[0].x, player.y + playerCollisionPoints[0].y, true)){
				leftBumping = true;
			}
			else{
				leftBumping = false;
			}
			 
			if(levels.hitobjects.hitTestPoint(player.x + playerCollisionPoints[1].x, player.y + playerCollisionPoints[1].y, true)){
				rightBumping = true;
			}
			else{
				rightBumping = false;
			}
			 
			if(levels.hitobjects.hitTestPoint(player.x + playerCollisionPoints[2].x, player.y + playerCollisionPoints[2].y, true)){
				upBumping = true;
			}
			else{
				upBumping = false;
			}
			 
			if(levels.hitobjects.hitTestPoint(player.x + playerCollisionPoints[3].x, player.y + playerCollisionPoints[3].y, true)){
				downBumping = true;
			}
			else{
				downBumping = false;
			}
			
			if(leftBumping){ //Игрок упёрся в левую стенку
				if(speedX < 0){
					speedX *= -0.5;
				}
			}
			 
			if(rightBumping){  //Игрок упёрся в правую стенку
				if(speedX > 0){
					speedX *= -0.5;
				}
			}
			 
			if(upBumping){  //Игрок упёрся в потолок
				if(speedY < 0){
					speedY = 0;
				}
			}
			
			if(downBumping){ //Игрок на земле
				if (playerLanding > 0 && !playerJumping){ //Если игрок в данный момент приземляется (анимация приземления)
					if (playerLanding == 5){
						player.gotoAndPlay('land');
					}
					playerWalking = false; //Исправляем для дальнейшей анимации ходьбы
					playerLanding--; //Считаем, сколько ему приземляться
				}
				else{
					playerJumping = false;
				}
				
				if(speedY > 0){
					speedY = 0;
				}
				
				if(key.isDown(key.SHIFT) && !playerJumping && playerLanding == 0){ //Прыжок.
					player.gotoAndPlay('jump');
					sounds[1].play();
					playerJumping = true; //Отключаем возможность прыгнуть, пока не приземлились
					playerLanding = 5;
					speedY = jumpConstant;
				}
			}
			else{
				speedY += gravityConstant;
				if (speedY > 0){
					if (!playerJumping){
						player.gotoAndPlay('fall');
						playerJumping = true;
						playerLanding = 5;
					}
				}
			}
			
			speedX *= friction; //Считаем скорость
			
			//Ограничиваем скорость
			if(speedX > maxspeedXConstant){ //вправо
				speedX = maxspeedXConstant;
			}
			else if(speedX < (maxspeedXConstant * -1)){ //влево
				speedX = (maxspeedXConstant * -1);
			}
			
			if(speedY > maxspeedYConstant){ //вправо
				speedY = maxspeedYConstant;
			}
			
			scrollX -= speedX; //Просчитываем скорость
			scrollY -= speedY;
			
			levels.x = scrollX; //Двигаем уровень
			levels.y = scrollY; 
			levels.bg2.x = scrollX * 0.5 - scrollX; //Делаем ассимитричное движение заднего фона
			
			if (!moveEnemies()){ //Перемещаем врагов
				playerHit(); //Проверяем попадания по игроку
			}
			
			if (levels.exit.hitTestObject(player)){ //и проверяем, добрался ли игрок до выхода. Если функция возвратила нам true, значит игрок умер
				gameObject = this;
				stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler); //Убиваем слушатель событий по входу в кадр
				this.setChildIndex(winScreen, winScreen.parent.numChildren-1); //Перемещаем экран победы наверх
				TweenLite.to(winScreen, 2, {alpha: 1}) //и отображаем "победу" (заливаем экран синим в течении двух секунд)
				TweenLite.delayedCall(4, function(){  //С задержкой в 4 секунды после выигрыша игрока,
					MovieClip(parent).gotoAndPlay('win'); //прыгаем в кадр "game_over"
					MovieClip(parent).removeChild(gameObject); //а также убираем объект игры с экрана
				});
			}
		}
		
		private function moveEnemies():Boolean{ //Функция для просчёта и отображения движения врагов. Так же возвращает нам true, если все враги убиты
			var allDead:Boolean = true;
			for (var s:int = 0; s < enemiesArray.length; s++){
				if (!enemiesArray[s].isDead()){
					allDead = false;
					//trace(enemiesArray[s].speed());
				}
			}
			return allDead;
		}
		
		private function playerHit():void{ //Функция для проверки попадания по игроку
			for (var s:int = 0; s < enemiesArray.length; s++){ //Проходимся по всему массиву с врагами
				if (player.hitTestObject(enemiesArray[s]) && playerHitTimer < 1){ //и проверяем, соприкасается ли игрок с одним из врагов
					sounds[Math.round(Math.random()*2 + 2)].play(); //Проигрываем звук попадания по игроку (рандомно один из трёх (2й, 3й или 4й элемент массива звуков)
					lives.text = String(int(lives.text) - 1); //Уменьшаем кол-во жизней на экране
					playerHitTimer = 60; //если да, то сбрасываем таймер обратного отсчёта задержки попадания по игроку (чтобы попадания считались не одно за другим на каждый кадр)
					this.setChildIndex(hitScreen, hitScreen.parent.numChildren-1); //Перемещаем экран попадания по игроку (кровь) на самый верх
					if (player.hit()){ //и выполняем функцию объекта player "hit()", которая уменьшает здоровье игрока и возвращает true, если у игрока не осталось здоровья
						sounds[5].play(); //Проигрываем звук смерти
						var gameObject = this; //Если функция возвратила нам true, значит игрок умер
						player.gotoAndPlay('die'); //Показываем анимацию смерти
						stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler); //Убиваем слушатель событий по входу в кадр
						TweenLite.delayedCall(3, function(){TweenLite.to(hitScreen, 2, {alpha: 1});}); //и отображаем "смерть" (заливаем экран красным в течении двух секунд с задержкой в три секунды)
						TweenLite.delayedCall(5, function(){  //С задержкой в 5 секунд после непосредственной "смерти" игрока,
							MovieClip(parent).gotoAndPlay('game_over'); //прыгаем в кадр "game_over"
							MovieClip(parent).removeChild(gameObject); //а также убираем объект игры с экрана
						});
					}
					else{
						//player.gotoAndPlay('hit'); //Если же игрок не умер, то отрисоввываем попадание
						TweenLite.to(hitScreen, 0.1, {alpha: 0.75});
						TweenLite.delayedCall(0.1, function(){TweenLite.to(hitScreen, 0.2, {alpha: 0});});
					}
				}
			}
			if (playerHitTimer > 0) playerHitTimer--; //И уменьшаем счётчик задержки попаданий
		}
		
		private function reloadAmmo():void{ //Функция перезарядки оружия
			ammo.push(new Ammo()); //Создаём новый патрон в интерфейсе
			magazine.addChild(ammo[ammo.length-1]); //Добавляем его на экран,
			ammo[ammo.length-1].y = 25; //задавая начальную позицию x/y
			ammo[ammo.length-1].x = (ammo.length-1)*20+45;
			//trace(ammo[ammo.length-1].x);
		}

		
		private function moveBullets():void{ //Двигаем пули на экране
			for (var i:int = 0; i < shots.length; i++){ //Проходим по всему массиву выпущенных пуль
				shots[i].x += shots[i].getSpeedX(); //Прибавляем позиции х пули её скорость
				shots[i].y += shots[i].getSpeedY(); //Прибавляем позиции х пули её скорость
				if (shots[i].x < -levels.x - 100 || shots[i].x > -levels.x +  900){ //Если пуля улетела за края экрана + 100 пикселей, то пуля нам больше не нужна
					trace('Bullet out of screen!');
					levels.removeChild(shots[i]); //Удаляем её
					shots.splice(i,1); //А так же удаляем пулю из массива
					//i--; //Компенсируем удалённую ячейку
					break; //Если пулю удалили, нет смысла продолжать выполнения этого цикла
				}
				
				if(levels.hitobjects.hitTestPoint(shots[i].x + levels.x, shots[i].y + levels.y, true)){ //Проверяем соприкосновение пули со стенками уровня
					trace('Bullet hits a wall!');
					levels.removeChild(shots[i]); //Удаляем пулю с экрана, если она коснулась стенки
					shots.splice(i,1); //Соответственно удаляем её и из массива
					break; //И прерываем данную стадию цикла
				}
				
				for (var o:int = 0; o < enemiesArray.length; o++){
					if(enemiesArray[o].hitTestObject(shots[i])){ //Проверяем соприкосновения пули с каждым врагом (попадание по врагу)
						trace('Bullet hits an enemy!');
						levels.removeChild(shots[i]); //Удаляем пулю с экрана, если она коснулась стенки
						shots.splice(i,1); //Соответственно удаляем её и из массива
						
						if (enemiesArray[o].hit()){
							trace('Enemy dies!');
							enemiesArray[o].gotoAndPlay('die');
							enemiesArray.splice(o,1); //Удаляем врага из массива врагов
						}
						break; //И прерываем данную стадию цикла
					}
				}
			}
		}
		
		private function movePlayer(moveTo:String):void{ //Двигаем игрока
			if (!playerWalking){ //Если игрок ещё не идёт
				playerWalking = true; //Для правильной анимации используем флаг ходьбы
				if (shotAnimationDelay == 0) player.gotoAndPlay('walk'); //Изображаем ходьбу человечка (движение тела)
				player.legs.gotoAndPlay('walk'); //Изображаем ходьбу человечка (движение ног)
			}
			switch (moveTo){ //Смотря в какую сторону идём, зеркально поворачиваем игрока по оси Х и ускоряем его
				case 'left':	speedX -= speedXConstant;
								player.scaleX = -1;
								break;
								
				case 'right':	speedX += speedXConstant;
								player.scaleX = 1;
								break;
			}
		}
		
		private function collision(from:String):void{ //Описываем действия, когда игрок касается уровня
			switch (from){ //Параметр from используется для указания, с какой стороны находится стенка
				case 'left':	if (speedX < 0){
									speedX *= -0.5;
								}
								break;
								
				case 'right':	if(speedX > 0){
									speedX *= -0.5;
								}
								break;
								
				case 'up':		if(speedY < 0){
									speedY = 0;
								}
								break;
								
				case 'down':	if(speedY > 0){
									speedY = 0.0;
								}
								break;
			}
		}
	}
}