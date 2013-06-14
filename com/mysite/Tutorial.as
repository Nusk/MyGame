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
			MovieClip(parent).setChildIndex(MovieClip(parent).soundButton, MovieClip(parent).soundButton.parent.numChildren-1); //Перемещаем енопку переключения звука наверх
			stage.addEventListener(KeyboardEvent.KEY_DOWN, action);
			btn.addEventListener(MouseEvent.CLICK, action);
		}
					  
		function action(e:Event):void{
			if (this.currentFrame < 4){ //Если не достигли последнего фрейма,
				this.gotoAndStop(currentFrame + 1); //То переходим на следующий
			}
			else{
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, action);
				btn.removeEventListener(MouseEvent.CLICK, action);
				MovieClip(parent).addChild(new Menu());
				MovieClip(parent).gotoAndPlay('menu');
			}
		}
	}
}
