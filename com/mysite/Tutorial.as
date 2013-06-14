package com.mysite {
	
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.display.Stage;
	import com.mysite.Menu;
	
	public class Tutorial extends MovieClip {
		private var thisObject:Object;
		
		public function Tutorial(){
			thisObject = this;
			MovieClip(parent).setChildIndex(MovieClip(parent).soundButton, MovieClip(parent).numChildren-1); //Перемещаем кнопку переключения звука наверх
			stage.addEventListener(KeyboardEvent.KEY_DOWN, action); //Слушатель события по нажатию клавиатуры
			btn.addEventListener(MouseEvent.CLICK, action); //Слушатель события клику мыши
		}
					  
		function action(e:Event):void{ //Функция, которую вызывают слушатели событий
			if (this.currentFrame < 4){ //Если не достигли последнего фрейма,
				this.gotoAndStop(currentFrame + 1); //То переходим на следующий
			}
			else{
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, action); //Удаляем слушатели событий
				btn.removeEventListener(MouseEvent.CLICK, action);
				MovieClip(parent).addChild(new Menu()); //Создаём новый объект меню, попутно добавляя его на сцену в объекте Base
				MovieClip(parent).gotoAndPlay('menu'); //И переключаем кадр на метку "меню"
			}
		}
	}
}
