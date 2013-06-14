package com.mysite{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.text.TextField;
	import flash.system.fscommand;
	import com.greensock.TweenMax;
	import com.greensock.easing.*;
	
	public class Menu extends MovieClip{
		
		private var menuItems:Array = new Array(); //Тут будут храниться кнопки
		private var txt:Array = ["Новая игра", "Что делать?", "Выйти"]; //Массив, в котором хранятся тексты кнопок = кнопок
		private var difficulties:Array = ["Лехко!", "Не лехко", "Трудна"]; //Массив текста сложности игры
		private var newGameSelected:Boolean = false; //Флаг выбора новой игры
		private var menuItemsNum = txt.length; //Длина массива с кнопками
		private var currentIndex:int = 0; //Активная кнопка
		private var activeButton:int = 0; //Выделеная кнопка
		private var animationIndex:int = 0; //Номер кнопки, чтобы запускать анимацию
		
		public function Menu(){ //Конструктор меню
			if(stage){ //Так как объект меню может создаваться ещё до того, как его поместили на сцену, проверяем, находится ли он уже на сцене
				init(null); //Если да, продолжаем с функции init()
			}
			else{ //Если же нет, то создаём слушатель событий, который срабатывает, когда меню добавляют на сцену. При срабатывании вызываем всё ту же init()
				addEventListener(Event.ADDED_TO_STAGE, init); 
			}
		}
		
		private function init(e:Event){ //Тут будем создавать меню
			removeEventListener(Event.ADDED_TO_STAGE, init); //удаляем уже ненужный слушатель событий
			MovieClip(parent).setChildIndex(MovieClip(parent).soundButton, MovieClip(parent).numChildren-1); //Перемещаем енопку переключения звука наверх
			menuBuilder(); //А потом, собственно, создаём меню
			animatePrincess(); //Помимо этого запускаем анимацию прицессы
		}
		
		//Отображаем анимацию принцессы
		private function animatePrincess(){
			TweenMax.delayedCall(Math.random()*3+1, function(){ //Запускаем функцию с случайно задержкой между 1 и 4 секундами
				if (Math.random() > 0.5){ //А так же случайным образом выбираем одно из действий (вероятность 50 на 50)
					princess.gotoAndPlay('hand'); //Машет ручкой
				}
				else{
					princess.gotoAndPlay('eyes'); //Моргает глазками
				}
				animatePrincess();
			});
		}
		
		//Создаём меню в зависимости от того, что находится в массиве текста кнопок
		private function menuBuilder():void{
			for(var i:int = 0; i < menuItemsNum; i++){
				menuItems[i] = new MenuButton(); //Создаём новую кнопку
				menuItems[i].name = i; //Даём ей имя, чтобы потом можно было определить, что это за кнопка
				menuItems[i].x = stage.stageWidth/2; //Ставим каждую кнопку в середину по координате Х
				menuItems[i].y = 400 + 75 * i; //И на начальную позицию У
				menuItems[i].labelText.text = txt[i]; //Изменяем текст кнопки
				menuItems[i].labelText.mouseEnabled = false; //И отключаем возможность выделения текста
				menuItems[i].buttonMode = true; //Делаем из объекта кнопки кнопку, чтоб указатель мыши был рукой
				addChild(menuItems[i]);
			}
			 //Устанавливаем слушатели событий для мыши и кнопок клавиатуры
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler); //Слушатель событий нажатия кнопок (общий для всей сцены)
			for (i = 0; i < menuItemsNum; i++){ //Для каждой кнопки
				menuItems[i].addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler); //Слушатель событий mouseover по одной из кнопок
				menuItems[i].addEventListener(MouseEvent.CLICK, menuButtonHandler); //Слушатель события клика мыши по одной из кнопок
			}
			addEffect(); //Выделяем первую кнопку
		}
		
		//Функция навигации по меню с помощью клавиатуры
		private function keyDownHandler(e:KeyboardEvent):void{
			if(e.keyCode == 38){ //Была нажата кнопка вверх
				if (currentIndex == 0){ //Если уже выбран самый верхний пункт, выбираем последний
					currentIndex = menuItemsNum - 1; //Устанавливаем максимальный индекс кнопки
				}
				else{ //В обратном случае выбираем вышестоящую кнопку
					currentIndex--; //Уменьшаем индекс активной кнопки (выбираем следующий пункт)
				}
			}
			else if(e.keyCode == 40){ //Была нажата кнопка вниз
				if (currentIndex == menuItemsNum - 1){ //Если уже выбрана самая последняя кнопка
					currentIndex = 0; //То выбираем первую кнопку
				}
				else{
					currentIndex++; //Если нет, то следующую
				}
			}
			else if(e.keyCode == 13){ //Был нажат энтер
				menuButtonHandler(); //Вызываем функцию для дальнейшей обработки в зависимости от активной кнопки
			}
			else if(e.keyCode == 27){ //Была нажата кэскейп
				if (newGameSelected){ //Если ранее был выбран пункт меню "Новая игра"
					newGameSelected = false; //Сбрасываем флаг новой игры
					for(var i:int = 0; i < menuItemsNum; i++){ //Для каждой из кнопок
						menuItems[i].labelText.text = txt[i]; //Сбрасываем текст каждой кнопки на начальный
						menuItems[i].alpha = 1; //Снова отображаем все кнопки
					}
				}
				else{ //а если не выбран пункт меню "New game", то просто:
					fscommand("quit"); //Выход из игры :) (в дебаг-плеере программы Adobe Flash не работает!)
				}
			}
			updateMenu();
		}
		
		//Функция нажатия кнопок меню (как мышью, так и клавиатурой)
		private function menuButtonHandler(e:MouseEvent = null){
			var destination:String;
			
			if (newGameSelected){
				destination = "game_intro"; //Если мы в меню выбора сложности игры, выбор любого пункта запустит игру
				MovieClip(parent).setDifficulty(currentIndex); //Сохраняем выбранный уровень сложности в глобальном объекте Base
				newGameSelected = false;
			}
			else{
				switch(currentIndex){ //Описываем, что будет происходить по нажатию разных пунктов меню
					case 0: //Новая игра
						choseDifficulty();
						return;
					case 1: //About
						destination = "game_tutorial";
						break;
					case 2: //Exit
						fscommand("quit"); //Выходим из игры
					default:
						destination = "game_menu";
				}
			}
			//Удаляем слушатели событий для действия клавиатуры и мыши
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler); //Слушатель событий нажатия кнопок (общий для всей сцены)
			for (var i:int = 0; i < menuItemsNum; i++){ //Для каждой кнопки
				menuItems[i].removeEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler); //Слушатель событий mouseover по одной из кнопок
				menuItems[i].removeEventListener(MouseEvent.CLICK, menuButtonHandler); //Слушатель события клика мыши по одной из кнопок
			}
			MovieClip(parent).gotoAndPlay(destination); //Перепрыгиваем к пункту destination в временной линии
			MovieClip(parent).removeChild(this); //А после удаляем меню с экрана, т.к. оно больше не нужно (сам объект не удаляем)
		}
		
		private function choseDifficulty():void{
			newGameSelected = true; //Меняем флаг выбора сложности
			for(var i:int = 0; i < menuItemsNum; i++){ //Меняем названия кнопок
				try{
					menuItems[i].labelText.text = difficulties[i];
				}
				catch (e:Error){
					menuItems[i].alpha = 0;
				}
			}
		}
		
		//Функция навигации по меню с помощью мыши
		private function mouseOverHandler(e:MouseEvent):void{
			currentIndex = int(e.currentTarget.name);
			updateMenu();
		}
		
		//Анимация кнопок меню при их выделении
		private function addEffect():void{
			TweenMax.to(menuItems[currentIndex], 1, {scaleX:1.5, scaleY:1.5, ease:Elastic.easeOut});
		}
		
		//Обратная анимация кнопок меню при их выделении
		private function removeEffect():void{
			TweenMax.to(menuItems[activeButton], 1, {scaleX:1, scaleY:1, ease:Elastic.easeOut});
		}
		
		//Функция смены активной кнопки
		private function updateMenu():void{
			if (activeButton != currentIndex){
				removeEffect();
				addEffect();
				activeButton = currentIndex;
			}
		}
	}
}