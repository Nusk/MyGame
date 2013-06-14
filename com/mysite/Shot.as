package com.classes {
	
	import flash.display.MovieClip;
	
	
	public class Shot extends MovieClip {
		private var speedX:int = 0;
		private var speedY:int = 0;
		
		public function Shot(speedX:int, speedY:int):void{
			this.speedX = speedX;
			this.speedY = speedY;
		}
		
		public function getSpeedX():int{
			return speedX;
		}
		
		public function getSpeedY():int{
			return speedY;
		}
	}
	
}
