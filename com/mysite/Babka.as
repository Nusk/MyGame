package com.mysite {
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	public class Babka extends MovieClip {
		private var dead:Boolean = false;
		
		public function Babka() {
			this.scaleX = this.scaleY = 0.5;
		}
		
		public function hit():void{
			if (!dead){
				this.dead = true;
				this.gotoAndPlay('die');
			}
		}
		
		public function isDead():Boolean{
			return this.dead;
		}
	}
	
}
