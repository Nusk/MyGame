package com.mysite {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.system.fscommand;
	import com.greensock.TweenMax;
	import com.greensock.easing.*;
	import com.senocular.KeyObject;
	
	public class Game extends MovieClip {
		private var hero:Hero; //Объект игрока
		private var key:KeyObject; //Клавиши
		private var isJumping:Boolean = false; //Флаг прыжка
		private var isOnFloor:Boolean = true; //Флаг соприкосновения с полом
		private var jumpStrength:int; //Сила прыжка
		private var isGettingStrength:Boolean = false; //Флаг, обозначающий изменения силы прыжка
		private var isReadyToJump:Boolean = false; //Флаг прыжка
		private var jumpMinimalStrength:int = 5;
		private var gravityStrength:Number = 0.9; //Контстанта гравитации
		private var isShooting:Boolean = false; //Флаг стрельбы
		private var speedY:Number = 0; //Скорость игрока по оси У (по оси Х не требуется)
		private var maxSpeedY:int = 25; //Максимальная скорость игрока по оси У
		private var levelArray:Array = new Array(); //Двухмерный массив для координат блоков земли
		private var gameSpeed:int = 10; //Активная скорость игры. Начальное значение 5, максимальное - 25
		private var increaseGameSpeedDelay:int = 0; //Шаг увеличения скорости игры (в секундах)
		private var enemies:Array = new Array(); //Массив с бабками
		private var level:int = 0; //Номер активного уровня
		private var newBlockDelay:int = 200; //Переменная, в которой просчитывается шаг удаления/создания блоков земли
		private var background:Background = new Background(); //Задний фон
		private var clouds:Clouds = new Clouds(); //Задний фон: облака
		private var metersLeft:int = 1000;
		private var ammo:int = 6;
		
		public function Game() {
			var notEmpty:Boolean = false, block:Object;
			hero = new Hero();
			hero.scaleX = -0.4;
			hero.scaleY = 0.4;
			hero.x = 250;
			key = new KeyObject(stage);
			increaseGameSpeed();
			this.addChild(background);
			background.y = 200;
			this.addChild(clouds);
			this.addChild(hero);
			this.setChildIndex(jumpMeter, this.numChildren-1);
			this.setChildIndex(meter, this.numChildren-1);
			this.setChildIndex(magazine, this.numChildren-1);
			this.setChildIndex(hero, this.numChildren-1);
			
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
			
			jumpMeter.steps.mask = jumpMeter.strengthMask;
			jumpMeter.jumpMinimalStrength.y = 52 * jumpMinimalStrength;
			this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
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
					hero.gotoAndPlay('land');
				}
			}
			else if(levelArray[1][1].type > -1 && levelArray[1][1].obj.hitbox.hitTestPoint(hero.x - 20, hero.y + 70, true) || 
					levelArray[1][2].type > -1 && levelArray[1][2].obj.hitbox.hitTestPoint(hero.x - 20, hero.y + 70, true)){
				hero.y = 430;
				isOnFloor = true;
				if (isJumping){
					isJumping = false;
					hero.gotoAndPlay('land');
				}
			}
			else{
				jumpMeter.strengthMask.height = 0;
				jumpStrength = 0;
				isOnFloor = false;
			}
			
			if (increaseGameSpeedDelay == 0){
				increaseGameSpeedDelay = 5 * int(stage.frameRate);
				increaseGameSpeed();
			}
			else{
				increaseGameSpeedDelay--;
			}
			if (!isShooting && key.isDown(key.SPACE) && ammo > 0){
				isShooting = true;
				
				TweenMax.delayedCall(0.3, function(){
					for (var o:int = 0; o < enemies.length; o++){
						enemies[o].hit();
					}
				});
				
				magazine.gotoAndPlay(7 - ammo);
				ammo--;
				hero.gotoAndPlay('shot');
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
						jumpStrength += 2;
						jumpMeter.strengthMask.height = jumpStrength * (jumpMeter.steps.height / 23);
						if (jumpStrength >= 25){
							isJumping = true; //Отключаем возможность прыгнуть, пока не приземлились
							isReadyToJump = false;
							speedY = -jumpStrength;
							jumpStrength = 0;
							hero.gotoAndPlay('jump');
							shotEnded(null);
							hero.addEventListener("animation_shot_end", jumpEnded);
						}
					}
					else if (!isReadyToJump){
						jumpMeter.strengthMask.height = 0;
						jumpStrength = 0;
					}
					else if (isReadyToJump){
						isJumping = true; //Отключаем возможность прыгнуть, пока не приземлились
						isReadyToJump = false;
						speedY = -jumpStrength;
						hero.gotoAndPlay('jump');
						shotEnded(null);
						hero.addEventListener("animation_jump_end", jumpEnded);
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
				//trace('dead');
				die();
			}
			else if (metersLeft <= 0){
				//trace('won');
			}
		}
		
		private function jumpEnded(e:Event):void{
			isJumping = false;
			hero.removeEventListener("animation_jump_end", jumpEnded);
		}
		
		private function shotEnded(e:Event):void{
			isShooting = false;
			hero.removeEventListener("animation_shot_end", shotEnded);
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
			if (gameSpeed > 25) return;
			gameSpeed += 1;
		}
		
		private function moveScreen():void{
			var speed:Number = gameSpeed/2 + 2;
			clouds.x -= gameSpeed/5;
			if (clouds.x <= -800){
				clouds.x = 0;
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
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			this.setChildIndex(switchScreen, this.numChildren-1);
			this.setChildIndex(loseScreen, this.numChildren-1);
			TweenMax.to(switchScreen, 0, {alpha: 1});
			TweenMax.to(loseScreen, 0, {alpha: 1});
			TweenMax.delayedCall(5, function(){
				MovieClip(parent).gotoAndPlay('game_over');
			});
		}
		
		private function won():void{
			this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			this.setChildIndex(switchScreen, this.numChildren-1);
			this.setChildIndex(winScreen, this.numChildren-1);
			TweenMax.to(switchScreen, 0, {alpha: 1});
			TweenMax.to(winScreen, 0, {alpha: 1});
			changeLevel();
			TweenMax.delayedCall(5, function(){
				TweenMax.to(switchScreen, 2, {alpha: 0});
				TweenMax.to(winScreen, 2, {alpha: 0});
				TweenMax.delayedCall(2, function(){this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);});
			});
		}
		
		private function changeLevel():void{
			level++;
			background.gotoAndPlay(2);
			for (var i:int = 0; i < 5; i++){
				if (levelArray[0][i] && levelArray[0][i].type > -1){
					levelArray[0][i].obj.gotoAndPlay(level);
				}
				if (levelArray[1][i] && levelArray[1][i].type > -1){
					levelArray[1][i].obj.gotoAndPlay(level);
				}
			}
		}
	}
}