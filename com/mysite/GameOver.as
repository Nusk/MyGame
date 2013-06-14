package com.classes {
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.events.Event;
	
	public class GameOver extends MovieClip {
		
		public function GameOver() {
			MovieClip(parent).setChildIndex(MovieClip(parent).soundControl, MovieClip(parent).soundControl.parent.numChildren-1); //Помещаем значок звука на верх
			button.addEventListener(MouseEvent.CLICK, function(){MovieClip(parent).gotoAndPlay("game");}); // Клик по кнопке возвращает нас в главное меню
		}
	}
	
}
