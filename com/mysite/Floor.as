package com.mysite {
	import flash.display.MovieClip;
	
	public class Floor extends MovieClip {
		
		public function Floor(frameNumber) {
			this.gotoAndPlay(frameNumber + 1);
		}
	}
}