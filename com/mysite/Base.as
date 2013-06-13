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
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.media.SoundMixer;
	
	public class Base extends MovieClip {
		//глобальные переменные
		private var difficulty:int = 0;
		private var sounds:Array = new Array();
		private var bgMusic: SoundChannel;
		private var soundOn:Boolean = true; //Флаг звука
		
		//---------------------
		public function Base() {
			addChild(new Menu());
			/*sounds[0] = new sFire(); //Звук стрельбы
			sounds[1] = new sJump(); //Звук прыжка
			sounds[2] = new sHit1(); //Звук удара 1
			sounds[3] = new sHit2(); //Звук удара 2
			sounds[4] = new sHit3(); //Звук удара 3
			sounds[5] = new sDie(); //Звук смерти игрока
			sounds[6] = new sBg(); //Музыка заднего фона
			bgMusic = sounds[6].play(); //Создаём новый звуковой канал и сохраняем туда плейбек звукового файлв
			bgMusic.addEventListener(Event.SOUND_COMPLETE, function(e:Event):void{bgMusic = sounds[6].play();}); //Повторяем музыку, когда она кончается
			
			soundControl.buttonMode = true; //Делаем кнопку звука похожей на кнопку :)
			soundControl.addEventListener(MouseEvent.CLICK, function():void{ //При клике по кнопке звука - отключаем звук
				muteSound(soundOn);
				soundOn = !soundOn; //Инвертируем флаг звука
				if (soundOn) soundControl.gotoAndPlay('on'); //Меняем изображение кнопки
				else soundControl.gotoAndPlay('off');
			});
			*/
		}
		
		private function keyDownHandler(e:KeyboardEvent){
			 /*if(e.keyCode == 27){
				this.addChild(menu);
				menu.toggleActions(); 
			 }*/
		}
		
		public function setDifficulty(difficulty):void{ //Даём возможность сохранять глобальную переменную, обозначающую сложность игры
			this.difficulty = difficulty;
			//trace('difficulty set to: ' + difficulty);
		}
		
		public function getDifficulty():int{ //Даём возможность считывать глобальную переменную, обозначающую сложность игры
			//trace('here your difficulty: ' + this.difficulty);
			return this.difficulty;
		}
		
		public function getSounds():Array{
			return sounds;
		}
		
		public function muteSound(mute:Boolean):void{
			var muteSound:int;
			if (mute) muteSound = 0 else muteSound = 1;
			SoundMixer.soundTransform = new SoundTransform(muteSound);
		}
	}
}

/*
По игровому процессу:
3. Доведи до логического завершения 1 раунд.
5. Может быть для врагов добавь движение туда - обратно и стрельбу, если они замечают персонажа.
*/