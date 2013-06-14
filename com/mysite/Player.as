package com.classes {
	
	import flash.display.MovieClip;
	
	public class Player extends MovieClip {
		private var health:int;
		
		public function Player(health) { //Конструктор игрока
			trace('player created!');
			this.health = health; //Даём ему здоровье
		}
		
		public function getHealth():int{
			return health; //Возаращаем здоровье
		}
		
		public function hit():Boolean{
			health--; //Отнимаем здоровье
			if (health < 1){
				trace('player is dying!')
				return true; //Если здоровья не осталось - игрок умирает. Возвраюаем true
			}
			else{
				return false; //А если осталось - то повезло, не умер. Возвращаем false
			}
		}
	}
	
}
