package com.mysite {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.events.Event;
	import com.senocular.KeyObject;
	import com.mysite.Menu;
	import flash.display.Stage;
	import flash.text.TextField;
	
	//Звуки
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.media.SoundMixer;
	
	public class Base extends MovieClip {
		//Глобальные переменные
		private var difficulty:int = 0;
		private var sounds:Object = new Object();
		private var bgMusic:SoundChannel;
		private var soundOn:Boolean = true; //Флаг звука
		
		//--------------------- ДЕЛАЕМ ЗВУК
		public function Base() {
			addChild(new Menu()); //Создаём новое меню
			sounds['shot1'] = new sShot1(); //Звук стрельбы 1
			sounds['shot2'] = new sShot2(); //Звук стрельбы 2
			sounds['shot3'] = new sShot3(); //Звук стрельбы 3
			sounds['hit1'] = new sHit1(); //Звук смерти бабки 1
			sounds['hit2'] = new sHit2(); //Звук смерти бабки 2
			sounds['hit3'] = new sHit3(); //Звук смерти бабки 3
			sounds['jump1'] = new sJump1(); //Звук прыжка 1
			sounds['jump2'] = new sJump2(); //Звук прыжка 2
			sounds['jump3'] = new sJump3(); //Звук прыжка 3
			sounds['die1'] = new sDie1(); //Звук смерти игрока 1
			sounds['die2'] = new sDie2(); //Звук смерти игрока 2
			sounds['die3'] = new sDie3(); //Звук смерти игрока 393
			sounds['fall1'] = new sFall1(); //Звук падения игрока 1
			sounds['fall2'] = new sFall2(); //Звук падения игрока 2
			sounds['fall3'] = new sFall3(); //Звук падения игрока 3
			sounds['bg1'] = new sBg1(); //Музыка заднего фона
			sounds['bg2'] = new sBg2(); //Музыка заднего фона
			sounds['bg3'] = new sBg3(); //Музыка заднего фона
			sounds['happyend'] = new sHappyend(); //Музыка хэппиэнда
			
			bgMusic = sounds['bg' + Math.floor(Math.random()*3+1)].play(); //Создаём новый звуковой канал и сохраняем туда плейбек звукового файлв
			
			bgMusic.addEventListener(Event.SOUND_COMPLETE, function(e:Event):void{
				bgMusic = sounds['bg'+Math.floor(Math.random()*3+1)].play();
			}); //Повторяем музыку, когда она кончается
			
			soundButton.buttonMode = true; //Делаем значок переключения звука кнопкой
			soundButton.addEventListener(MouseEvent.CLICK, function():void{ //При нажатии на кнопку звука переключаем звук и меняем иконку
				muteSound(soundOn); //Включаем/выключаем звук
				soundOn = !soundOn; //Инвертируем флаг звука
				if (soundOn) soundButton.gotoAndPlay('on'); //Меняем изображение кнопки
				else soundButton.gotoAndPlay('off');
			});
			this.setChildIndex(soundButton, this.numChildren-1); //Кнопку управления звуком
		}
		
		public function setDifficulty(difficulty):void{ //Даём возможность сохранять глобальную переменную, обозначающую сложность игры
			this.difficulty = difficulty;
			//trace('difficulty set to: ' + difficulty);
		}
		
		public function getDifficulty():int{ //Даём возможность считывать глобальную переменную, обозначающую сложность игры
			//trace('here your difficulty: ' + this.difficulty);
			return this.difficulty;
		}
		
		public function getSounds():Object{
			return sounds;
		}
		
		public function muteSound(mute:Boolean):void{ //Заглушаем звук, если он включен и включаем, если выключен
			var muteSound:int;
			if (mute) muteSound = 0 else muteSound = 1;
			SoundMixer.soundTransform = new SoundTransform(muteSound);
		}
		public function getBackgroundMusic():SoundChannel{
			return this.bgMusic;
		}
	}
}