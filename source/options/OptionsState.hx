package options;

import online.states.RoomState;
import states.MainMenuState;
import backend.StageData;
#if (target.threaded)
import sys.thread.Thread;
import sys.thread.Mutex;
#end

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics and Performance', 'Visuals and UI', 'Gameplay', 'Mobile Options'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	public static var onOnlineRoom:Bool = false;
	#if (target.threaded) var mutex:Mutex = new Mutex(); #end

	function openSelectedSubstate(label:String) {
		if (label != "Adjust Delay and Combo"){
			removeTouchPad();
			persistentUpdate = false;
		}
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				switch (controls.mobileC)
				{
					case true:
						persistentUpdate = false;
						openSubState(new mobile.substates.MobileControlSelectSubState());
					default: openSubState(new options.ControlsSubState());
				}
			case 'Graphics and Performance':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				FlxG.switchState(() -> new options.NoteOffsetState());
			case 'Mobile Options':
				openSubState(new mobile.options.MobileOptionsSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", "Options");
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		#if (target.threaded)
		Thread.create(()->{
			mutex.acquire();

			for (music in VisualsUISubState.pauseMusics)
			{
				if (music.toLowerCase() != "none")
					Paths.music(Paths.formatToSongPath(music));
			}

			mutex.release();
		});
		#end

		addTouchPad('UP_DOWN', 'A_B');

		super.create();

		online.GameClient.send("status", "In the Game Options");
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
		controls.isInSubstate = false;
        removeTouchPad();
		addTouchPad('UP_DOWN', 'A_B');
		persistentUpdate = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else if (onOnlineRoom) {
				LoadingState.loadAndSwitchState(new RoomState());
			}
			else FlxG.switchState(() -> new MainMenuState());
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}