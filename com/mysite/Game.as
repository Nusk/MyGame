package com.mysite {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.system.fscommand;
	import com.greensock.TweenMax;
	import com.greensock.easing.*;
	import com.senocular.KeyObject;
	
	public class Game extends MovieClip {
		private var hero:Hero; //Объект игрока
		private var key:KeyObject; //Клавиши
		private var screen:MovieClip;
		private var difficulty:int = MovieClip(parent).getDifficulty();
		private var isJumping:Boolean = false; //Флаг прыжка
		private var isOnFloor:Boolean = true; //Флаг соприкосновения с полом
		private var jumpStrength:int; //Сила прыжка
		private var isGettingStrength:Boolean = false; //Флаг, обозначающий изменения силы прыжка
		private var isReadyToJump:Boolean = false; //Флаг прыжка
		private var jumpMinimalStrength:int = 5;
		private var gravityStrength:Number = 0.9; //Контстанта гравитации
		private var isShooting:Boolean = false; //Флаг стрельбы
		private var speedY:Number = 0; //Скорость игрока
		private var maxSpeedY:int = 25; //Максимальная скорость игрока
		private var levelArray:Array = new Array(); //Двухмерный массив для координат блоков земли
		private var gameSpeed:int = 5 + 5 * difficulty;; //Активная скорость игры. Начальное значение 5, максимальное - 25
		private var increaseGameSpeedDelay:int = 0; //Шаг увеличения скорости игры (в секундах)
		private var enemies:Array = new Array(); //Массив с бабками
		private var level:int = 0; //Номер активного уровня
		private var newBlockDelay:int = 200; //Переменная, в которой просчитывается шаг удаления/создания блоков земли
		private var background:Background = new Background(); //Задний фон
		private var clouds:Clouds = new Clouds(); //Задний фон: облака
		private var metersLeft:int = 1000 + 500 * difficulty; //Сколько метров осталось в зависимости от уровня сложности
		private var ammo:int = 6; //Кол-во патронов
		private var lives:int = 3 + (3 - difficulty); //Кол-во жизней, зависит от сложности игры
		private var immortal:int = 2 * int(stage.frameRate); //Бессмертие (чтобы не умирать, если вдруг появился на бабке)
		private var sounds:Object; //Массив звуков (берётся из основного объекта Base)
		private var thisGame:Object;
		private var isPaused:Boolean = false;
		private var pauseScreen:Pause = new Pause();
		private var bag:String = '';
		
		public function Game() {
			var notEmpty:Boolean = false, block:Object;
			sounds = MovieClip(parent).getSounds(); //Берём звуки из главного объекта
			hero = new Hero();
			hero.scaleX = -0.4;
			hero.scaleY = 0.4;
			hero.x = 250;
			livesDisplay.txt.text = String(lives);
			key = new KeyObject(stage);
			increaseGameSpeed();
			this.addChild(background);
			background.y = 200;
			this.addChild(clouds);
			//Перемещаем все объекты управления интерфейса на самый верх
			this.setChildIndex(jumpMeter, this.numChildren-1); //Счётчик силы прыжка
			this.setChildIndex(meter, this.numChildren-1); //Счётчик оставшихся метров
			this.setChildIndex(magazine, this.numChildren-1); //Счётчик патронов
			this.setChildIndex(livesDisplay, this.numChildren-1); //Счётчик жизней
			MovieClip(parent).setChildIndex(MovieClip(parent).soundButton, MovieClip(parent).soundButton.parent.numChildren-1); //Кнопку переключения звука
			this.addChild(hero);
			
			levelArray[0] = new Array();
			levelArray[1] = new Array();
			levelArray[0][0] = {obj: null, type: -1}; //Создаём пустые объекты для цикла
			levelArray[1][0] = {obj: null, type: -1};
			
			for (var i:int = 0; i < 5; i++){
				block = createNextBlock(levelArray[0][i].type, true);
				levelArray[0].push({obj: block.obj, type: block.type});
				if(block.type > -1){
					notEmpty = false;
					this.addChild(levelArray[0][levelArray[0].length-1].obj);
					levelArray[0][levelArray[0].length-1].obj.x = i * 200;
					levelArray[0][levelArray[0].length-1].obj.y = 250;
				}
				
				block = createNextBlock(levelArray[1][i].type, true);
				levelArray[1].push({obj: block.obj, type: block.type});
				if(block.type > -1){
					this.addChild(levelArray[1][levelArray[1].length-1].obj);
					levelArray[1][levelArray[1].length-1].obj.x = i * 200;
					levelArray[1][levelArray[1].length-1].obj.y = 500;
				}
			}
			/*
			for(var t:Object in levelArray[0]){
  				trace(t + " : " + levelArray[0][t].type);
			}
			*/
			levelArray[0].splice(0, 1);
			levelArray[1].splice(0, 1);
			
			if (levelArray[0][1].type < 0){
				hero.y = 400;
			}
			else{
				hero.y = 150;
			}
			
			pauseScreen.x = stage.stageWidth / 2;
			pauseScreen.y = stage.stageWidth / 2 - pauseScreen.height/2 + 50;
			
			jumpMeter.steps.mask = jumpMeter.strengthMask;
			jumpMeter.jumpMinimalStrength.y = 52 * jumpMinimalStrength;
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			
			this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			thisGame = this;
		}
		
		private function enterFrameHandler(e:Event):void{
			meter.txt.text = metersLeft;
			metersLeft--;
			
			moveScreen(); //"Бежим", т.е. двигаем задний фон и блоки земли
			if(levelArray[0][1].type > -1 && levelArray[0][1].obj.hitbox.hitTestPoint(hero.x - 20, hero.y + 70, true) || 
			   levelArray[0][2].type > -1 && levelArray[0][2].obj.hitbox.hitTestPoint(hero.x - 20, hero.y + 70, true) && speedY > 0){
				hero.y = 190;
				isOnFloor = true;
				if (isJumping){
					isJumping = false;
					hero.gotoAndPlay('land' + bag);
				}
			}
			else if(levelArray[1][1].type > -1 && levelArray[1][1].obj.hitbox.hitTestPoint(hero.x - 20, hero.y + 70, true) || 
					levelArray[1][2].type > -1 && levelArray[1][2].obj.hitbox.hitTestPoint(hero.x - 20, hero.y + 70, true)){
				hero.y = 430;
				isOnFloor = true;
				if (isJumping){
					isJumping = false;
					hero.gotoAndPlay('land' + bag);
				}
			}
			else{
				jumpMeter.strengthMask.height = 0;
				jumpStrength = 10;
				isOnFloor = false;
			}
			
			if (increaseGameSpeedDelay == 0){
				increaseGameSpeedDelay = 5 * int(stage.frameRate);
				increaseGameSpeed();
			}
			else{
				increaseGameSpeedDelay--;
			}
			
			if (!isShooting && key.isDown(key.SPACE) && ammo > 0 && immortal == 0){
				isShooting = true;
				
				TweenMax.delayedCall(0.3, function(){
					for (var o:int = 0; o < enemies.length; o++){
						enemies[o].hit();
						sounds['hit'+Math.floor(Math.random()*3+1)].play();
					}
				});
				
				magazine.gotoAndPlay(7 - ammo);
				ammo--;
				hero.gotoAndPlay('shot' + bag);
				sounds['shot'+Math.floor(Math.random()*3+1)].play();
				hero.addEventListener("animation_shot_end", shotEnded);
			}
			if(isOnFloor){ //Игрок на земле
				speedY = 0;
				isJumping = false;
				if(!isJumping){ //Если игрок ещё не находится в прыжке
					if (key.isDown(key.UP)){ //При нажатии стрелки вверх
						if (jumpStrength > 5){ //Флаг готовности к прыжку. Минимальная сила, нажная для прыжка: 5
							isReadyToJump = true;
						}
						else{
							isReadyToJump = false;
						}
						jumpStrength += 3;
						jumpMeter.strengthMask.height = jumpStrength * (jumpMeter.steps.height / 23);
						if (jumpStrength >= 30){ //Прыгаем автоматически при достижении максимальной силы прыжка
							isJumping = true; //Отключаем возможность прыгнуть, пока не приземлились
							isReadyToJump = false;
							speedY = -jumpStrength;
							jumpStrength = 10;
							hero.gotoAndPlay('jump' + bag);
							shotEnded(null);
							hero.addEventListener("animation_shot_end", jumpEnded); //Слушатель событий для окончания анимации (событие создаётся в последней кадре мувиклипа
							sounds['jump'+Math.floor(Math.random()*3+1)].play(); //Звук прыжка
							isShooting = false;
						}
					}
					else if (!isReadyToJump){
						jumpMeter.strengthMask.height = 0;
						jumpStrength = 10;
					}
					else if (isReadyToJump){ //Прыгаем, если отпускаем кнопку "прыжок"
						sounds['jump'+Math.floor(Math.random()*3+1)].play(); //Звук прыжка
						isJumping = true; //Отключаем возможность прыгнуть, пока не приземлились
						isReadyToJump = false;
						speedY = -jumpStrength;
						hero.gotoAndPlay('jump' + bag);
						shotEnded(null);
						isShooting = false;
						hero.addEventListener("animation_jump_end", jumpEnded); //Слушатель событий для окончания анимации (событие создаётся в последней кадре мувиклипа
					}
					//sounds[1].play();
				}
			}
			else{
				if (speedY < maxSpeedY){
					speedY += gravityStrength;
				}
				if (speedY < 0){
					if (!isJumping){
						isJumping = true;
					}
				}
			}
			
			newBlockDelay -= (gameSpeed/2+1);
			
			hero.y += speedY; //Просчитываем скорость и двигаем героя по вертикали
			
			var hitByBabkas:Boolean = false;
			for (var s:int = 0; s < enemies.length; s++){
				if (!enemies[s].isDead() && enemies[s].hitbox.hitTestPoint(hero.x - 20, hero.y, true)){
					hitByBabkas = true;
				}
			}
			if (hero.y > 600 || hitByBabkas){
				if (immortal <= 0){
					if (hitByBabkas){
						sounds['die'+Math.floor(Math.random()*3+1)].play();
						hero.alpha = 0;
					}
					else{
						if (immortal > 0){ //Если падаем, пока бессмертны
							immortal = 4 * int(stage.frameRate); //Делаем игрока невосприимчивым к смерти (если вдруг падаем)
						}
						else{
							sounds['fall'+Math.floor(Math.random()*3+1)].play();
						}
					}
					die();
				}
			}
		
			if (immortal > 0){
				immortal--;
			}
		
			if (metersLeft <= 0){
				win();
			}
		}
		
		private function jumpEnded(e:Event):void{
			isJumping = false; //Заканчиваем прыжок
			hero.removeEventListener("animation_jump_end", jumpEnded); //Слушатель событий для окончания анимации (событие создаётся в последней кадре мувиклипа
			isShooting = false;
		}
		
		private function shotEnded(e:Event):void{
			isShooting = false; //Заканчиваем стрельбу
			hero.removeEventListener("animation_shot_end", shotEnded); //Слушатель событий для окончания анимации (событие создаётся в последней кадре мувиклипа
		}
		
		private function createNextBlock(previousBlock:int, notEmpty:Boolean = false):Object{
			var frame:int, newBlock:Floor;
			if (previousBlock == -1 || (notEmpty && previousBlock == -1)){ //Если предыдущий блок был пустым (т.е. блока не было)
				if (!notEmpty) frame = Math.floor(Math.random()*4-1); //То создаём начинающий, единичный или пустой блок
				else frame = Math.floor(Math.random()*4-1); //То создаём начинающий или единичный блок
			}
			else if ((previousBlock == 0 || previousBlock == 1 || previousBlock == 4) && !notEmpty){ //Если предыдущий блок был единичным
				frame = -1; //То следующий будет пустым
			}
			else if (previousBlock == 2 || previousBlock == 3){ //Если предыдущий блок был начинающим или продолжающим
				frame = Math.floor(Math.random()*2 + 3); //То создаём продолжающий или заканчивающий блок
			}
			else if (notEmpty){ //Во всех других случаях если функции был передан параметр notEmpty = true
				frame = Math.floor(Math.random()+1); //То создаём одиночный блок
			}
			
			if (frame < 0){ //Если был создан пустой блок
				newBlock = null;
			}
			else{
				newBlock = new Floor(frame + level*5);
			}
			return {obj:newBlock, type:frame};
		}
		
		private function increaseGameSpeed():void{
			if (gameSpeed > 25 + 5 * difficulty) return; //
			gameSpeed += 2;
		}
		
		private function keyDownHandler(e:KeyboardEvent):void{
			if(e.keyCode == 27){
				pauseScreen.yes.buttonMode = true;
				pauseScreen.no.buttonMode = true;
				
				function enterClicked(e:KeyboardEvent):void{
					if(e.keyCode == 13){
						yesClicked(null);
						stage.removeEventListener(KeyboardEvent.KEY_DOWN, enterClicked);
					}
				}
				stage.addEventListener(KeyboardEvent.KEY_DOWN, enterClicked);
				var i:int = 0;
				function yesClicked(e:MouseEvent):void{
					isPaused = false;
					pauseScreen.yes.removeEventListener(MouseEvent.CLICK, yesClicked);
					pauseScreen.no.removeEventListener(MouseEvent.CLICK, noClicked);
					thisGame.removeEventListener(Event.ENTER_FRAME, enterFrameHandler); //Приостанавливаем игру
					stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
					MovieClip(parent).addChild(new Menu());
					gotoAndPlay('menu');
				}
				
				function noClicked(e:MouseEvent):void{
					isPaused = false;
					pauseScreen.yes.removeEventListener(MouseEvent.CLICK, yesClicked);
					pauseScreen.no.removeEventListener(MouseEvent.CLICK, noClicked);
					thisGame.addEventListener(Event.ENTER_FRAME, enterFrameHandler); //Запускаем игру
					thisGame.removeChild(pauseScreen);
					switchScreen.alpha = 0;
					hero.play();
					for(var i:int = 0; i < enemies.length; i++){
						enemies[i].play();
					}
				}
				
				if (!isPaused){
					isPaused = true;
					thisGame.setChildIndex(switchScreen, this.numChildren-1);
					switchScreen.alpha = 1;
					thisGame.addChild(pauseScreen);
					thisGame.removeEventListener(Event.ENTER_FRAME, enterFrameHandler); //Приостанавливаем игру
					pauseScreen.yes.addEventListener(MouseEvent.CLICK, yesClicked);
					pauseScreen.no.addEventListener(MouseEvent.CLICK, noClicked);
					hero.stop();
					for(i = 0; i < enemies.length; i++){
						enemies[i].stop();
					}
				}
				else{
					isPaused = false;
					thisGame.removeChild(pauseScreen);
					switchScreen.alpha = 0;
					thisGame.addEventListener(Event.ENTER_FRAME, enterFrameHandler); //Запускаем игру
					pauseScreen.yes.removeEventListener(MouseEvent.CLICK, yesClicked);
					pauseScreen.no.removeEventListener(MouseEvent.CLICK, noClicked);
					hero.play();
					for(i = 0; i < enemies.length; i++){
						enemies[i].play();
					}
				}
			}
		}
		
		private function moveScreen():void{
			var speed:Number = gameSpeed/2 + 2;
			if (clouds.alpha == 0){ //Если облака скрыты, то нет и нужны их перемещать
				clouds.x -= gameSpeed/5;
				if (clouds.x <= -800){
					clouds.x = 0;
				}
			}
			
			background.x -= gameSpeed/2;
			if (background.x <= -800){
				background.x = 0;
			}
			for (var n:int = 0; n < enemies.length; n++){ //Двигаем бабок
				enemies[n].x -= speed; //Двигаем бабку по оси Х
				if (enemies[n].x < -100){ //Если бабка уехала за экран
					this.removeChild(enemies[n]); //Удаляем бабку с экрана
					enemies[n] = null; //Удаляем объект бабки
					enemies.splice(n,1); //Очищаем массив от пустого слота
					n--; //Подстраиваем цикл
				}
			}
			for (var i:int = 0; i < 5; i++){
				if (levelArray[0][i] && levelArray[0][i].type > -1){
					levelArray[0][i].obj.x -= speed;
				}
				if (levelArray[1][i] && levelArray[1][i].type > -1){
					levelArray[1][i].obj.x -= speed;
				}
			}
			
			if (newBlockDelay <= 0){
				newBlockDelay = 200;
				
				var notEmpty:Boolean = false, block:Object;
				
				if (levelArray[0][0] && levelArray[0][0].type > -1){
					try{
						this.removeChild(levelArray[0][0].obj);
					}
					catch(error:Error){
						trace('Nothing was deleted!');
					}
				}
				if (levelArray[0][1] && levelArray[1][0].type > -1){
					try{
						this.removeChild(levelArray[1][0].obj);
					}
					catch(error:Error){
						trace('Nothing was deleted!');
					}
				}
				levelArray[0].splice(0, 1);
				levelArray[1].splice(0, 1);
				
				block = createNextBlock(levelArray[0][levelArray[0].length-1].type);
				levelArray[0].push({obj: block.obj, type: block.type});
				if(block.type > -1){
					notEmpty = false;
					this.addChild(levelArray[0][levelArray[0].length-1].obj);
					levelArray[0][levelArray[0].length-1].obj.x = (levelArray[0].length - 1) * 200;
					levelArray[0][levelArray[0].length-1].obj.y = 250;
					createBabka(100);
				}
				else{
					notEmpty = true;
				}
				block = createNextBlock(levelArray[1][levelArray[1].length-1].type, notEmpty);
				levelArray[1].push({obj: block.obj, type: block.type});
				if(block.type > -1){
					notEmpty = false;
					this.addChild(levelArray[1][levelArray[1].length-1].obj);
					levelArray[1][levelArray[1].length-1].obj.x = (levelArray[1].length - 1) * 200;
					levelArray[1][levelArray[1].length-1].obj.y = 500;
					createBabka(350);
				}
			}
		}
		
		private function createBabka(position:int):void{
			var chance:Number = Math.random();
			if (chance > 0.75){
				enemies.push(new Babka());
				enemies[enemies.length-1].x = 900;
				enemies[enemies.length-1].y = position;
				this.addChild(enemies[enemies.length-1]);
			}
		}
		
		private function die():void{
			isShooting = false; //Снова позволяем стрелять
			if (lives > 0){
				if (immortal <= 0){
					lives--; //Отнимаем жизни только, если герой уже смертен
				}
				else if (hero.y > 600 && immortal > 0){ //Не даём игроку упасть
					hero.y = 0;
					immortal = 3 * int(stage.frameRate); //Делаем игрока невосприимчивым к смерти
				}
				TweenMax.delayedCall(1, function():void{ //Перезапускаем игрока
					hero.y = 0;
					speedY = 0;
					hero.alpha = 1;
				});
				livesDisplay.txt.text = String(lives);
				immortal = 3 * int(stage.frameRate); //Делаем игрока невосприимчивым к смерти
			}
			else{
				this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				this.setChildIndex(switchScreen, this.numChildren-1);
				this.setChildIndex(loseScreen, this.numChildren-1);
				switchScreen.alpha = 1;
				loseScreen.alpha = 1;
				TweenMax.delayedCall(3, function(){
					MovieClip(parent).gotoAndPlay('game_over');
				});
			}
		}
		
		private function win():void{
			winScreen.gotoAndStop(level+1);
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			this.setChildIndex(switchScreen, this.numChildren-1);
			this.setChildIndex(winScreen, this.numChildren-1);
			switchScreen.alpha = 1;
			winScreen.alpha = 1;
			if (level == 1){
				TweenMax.delayedCall(3, function():void{
					TweenMax.to(winScreen, 2, {alpha:0});
				});
				TweenMax.delayedCall(5, function():void{
					screen = new Level1End();
					thisGame.addChild(screen);
					screen.x = 400;
					screen.y = 400;
					TweenMax.delayedCall(2.7, function():void{
						TweenMax.to(screen, 2, {alpha:0});
						bag = '_bag'; //Для дальнейшей анимации с рюкзаком
						resume();
					});
				});
			}
			else{
				resume();
			}
			function resume():void{
				if (changeLevel()){
					immortal = 0;
					TweenMax.delayedCall(3, function(){ //В течении трёх секунд показываем заставку
						TweenMax.to(switchScreen, 2, {alpha:0}); //Потом убираем экраны в течении двух секунд
						TweenMax.to(winScreen, 2, {alpha:0});
						TweenMax.delayedCall(2, function(){ //С задержкой в две секунды выполняем
							gameSpeed = 10; //Сбрасываем скорость игры
							metersLeft =  1000 + 500 * difficulty; //Обновляем расстояние до финиша
							thisGame.addEventListener(Event.ENTER_FRAME, enterFrameHandler); //Снова запускаем игру
						});
					});
				}
			}
		}
		
		private function changeLevel():Boolean{
			if (level == 2){ //Если достигли последнего уровня)
				thisGame.removeEventListener(Event.ENTER_FRAME, enterFrameHandler); //Останавливаем игру
				TweenMax.to(MovieClip(parent).getBackgroundMusic(), 2, {volume:0}); //Постепенно заглушаем музыку
				MovieClip(parent).getBackgroundMusic().stop();
				sounds['happyend'].play();
				winScreen.play();
				TweenMax.to(MovieClip(parent).getBackgroundMusic(), 2, {volume:1}); //Постепенно включаем музыку
				return false;
			}
			hero.y = 0; //Перемещаем персонажа наверх
			speedY = 0; //Сбрасываем скорость
			isShooting = false; //Разрешаем стрелять
			ammo = 6; //Перезаряжаем пистолет
			magazine.gotoAndPlay(0); //Снова рисуем все шесть патронов
			level++; //Увеличиваем активный уровень
			lives += 3 - difficulty; //Прибавляем жизни, зависит от сложности игры
			if (level == 1){ //В замке облаков нет
				clouds.alpha = 0; //Скрываем облака
			}
			else{
				clouds.alpha = 1; //Или отображаем их
			}
			background.gotoAndPlay(2);
			for (var i:int = 0; i < 5; i++){
				if (levelArray[0][i] && levelArray[0][i].type > -1){
					levelArray[0][i].obj.gotoAndPlay(levelArray[0][i].obj.currentFrame + 5);
				}
				if (levelArray[1][i] && levelArray[1][i].type > -1){
					levelArray[1][i].obj.gotoAndPlay(levelArray[1][i].obj.currentFrame + 5);
				}
			}
			return true;
		}
	}
}